# Flujo de Funcionamiento y Comunicaciones — ChefGPT2

El siguiente diagrama ilustra el flujo de los datos desde arriba hacia abajo (Top-Down), detallando qué protocolos y puertos se utilizan en la comunicación entre cada uno de los componentes de la arquitectura.

```mermaid
flowchart TD
    %% Entidades Externas
    Client([📱 Cliente / Usuario])

    %% AWS Network / Load Balancing
    subgraph Red Pública
        ALB[⚖️ AWS Application Load Balancer<br/>Punto de entrada]
    end

    %% Capa de Aplicación (Microservicios)
    subgraph Subredes Privadas (VPC)
        API1[🚀 FastAPI Backend 1<br/>EC2]
        API2[🚀 FastAPI Backend 2<br/>EC2]
        
        RabbitMQ((🐰 RabbitMQ Broker<br/>Exchange: 'logs'))
        
        Worker1[⚙️ Worker Process 1<br/>Consumidor]
        Worker2[⚙️ Worker Process 2<br/>Consumidor]
        
        MongoDB[(🍃 MongoDB<br/>Colección: 'logs')]
    end

    %% Configuración Centralizada
    SSM[[🔐 AWS SSM Parameter Store<br/>Guarda IPs Privadas]]

    %% Flujo de Configuración (Lecturas)
    API1 -.->|Lee IPs| SSM
    API2 -.->|Lee IPs| SSM
    Worker1 -.->|Lee IPs| SSM
    Worker2 -.->|Lee IPs| SSM

    %% Flujo Principal de Datos
    Client ==>|1. Petición HTTP POST /logs<br/>Puerto 80| ALB
    
    ALB ==>|2a. Balanceo HTTP<br/>Puerto 8000| API1
    ALB ==>|2b. Balanceo HTTP<br/>Puerto 8000| API2
    
    API1 ==>|3. Publica Mensaje Rápido<br/>AMQP - Puerto 5672| RabbitMQ
    API2 ==>|3. Publica Mensaje Rápido<br/>AMQP - Puerto 5672| RabbitMQ
    
    RabbitMQ ==>|4. Entrega asíncrona (Round-Robin)<br/>Cola Compartida 'logs_queue'| Worker1
    RabbitMQ ==>|4. Entrega asíncrona (Round-Robin)<br/>Cola Compartida 'logs_queue'| Worker2
    
    Worker1 ==>|5. Inserta Log (JSON + Timestamp)<br/>MongoDB Wire - Puerto 27017| MongoDB
    Worker2 ==>|5. Inserta Log (JSON + Timestamp)<br/>MongoDB Wire - Puerto 27017| MongoDB

    %% Estilos
    classDef public fill:#f9f9f9,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5;
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#232F3E;
    classDef api fill:#4B8BBE,stroke:#306998,stroke-width:2px,color:white;
    classDef mq fill:#FF6600,stroke:#333,stroke-width:2px,color:white;
    classDef db fill:#47A248,stroke:#333,stroke-width:2px,color:white;
    classDef config fill:#8c4b9e,stroke:#333,stroke-width:2px,color:white;
    
    class ALB aws;
    class API1,API2,Worker1,Worker2 api;
    class RabbitMQ mq;
    class MongoDB db;
    class SSM config;
```

### 📝 Explicación de las Comunicaciones

1. **Ingreso (Público):** El usuario envía un log mediante una solicitud HTTP al Load Balancer, el cual es el único componente expuesto a Internet.
2. **Balanceo (Interno):** El ALB distribuye la carga equitativamente hacia una de las APIs (FastAPI) a través del puerto 8000 en la red privada de AWS.
3. **Publicación Asíncrona:** La API, que previamente obtuvo las IPs de conexión consultando el AWS SSM, se conecta al broker de RabbitMQ por el puerto 5672 y deposita el mensaje casi instantáneamente, permitiéndole responder al cliente sin esperar a la base de datos.
4. **Consumo Competitivo:** El broker almacena el log en la cola compartida. Múltiples *Workers* están conectados esperando mensajes. RabbitMQ le entregará el log a un solo Worker disponible para evitar que se guarde dos veces (patrón Competing Consumers).
5. **Persistencia Final:** El Worker procesa el mensaje, le añade metadatos si es necesario, y finalmente establece una conexión TCP (puerto 27017) con MongoDB para insertar el registro de forma permanente.
