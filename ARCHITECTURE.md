# KRT-Comms for Discord - System Architecture

**Version:** 1.0  
**Last Updated:** 2026-02-07

## Overview

This document describes the detailed system architecture for KRT-Comms for Discord, a voice communication system designed for multi-frequency push-to-talk communications with Discord integration.

## High-Level Architecture

```
                           Internet
                              │
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            │                 │                 │
    ┌───────▼────────┐ ┌─────▼──────┐  ┌──────▼────────┐
    │  Client App    │ │ Client App │  │  Discord Bot  │
    │  (Desktop)     │ │ (Desktop)  │  │               │
    └───────┬────────┘ └─────┬──────┘  └──────┬────────┘
            │                │                 │
            │ HTTPS/WSS     │                 │ HTTPS
            │ UDP (Audio)   │                 │
            │                │                 │
    ┌───────▼────────────────▼─────────────────▼────────┐
    │              Load Balancer / API Gateway           │
    └───────┬────────────────┬─────────────────┬────────┘
            │                │                 │
            │                │                 │
    ┌───────▼───────┐ ┌─────▼──────┐  ┌──────▼─────────┐
    │ Control       │ │   Voice    │  │   Discord      │
    │ Service       │ │   Service  │  │   Service      │
    │ (REST/WS)     │ │   (UDP)    │  │   (Bot API)    │
    └───────┬───────┘ └─────┬──────┘  └──────┬─────────┘
            │                │                 │
            │                │                 │
    ┌───────▼────────────────▼─────────────────▼────────┐
    │              Data Layer                            │
    │  ┌──────────────┐          ┌─────────────┐        │
    │  │  PostgreSQL  │          │   Redis     │        │
    │  │  (Persistent)│          │   (Cache)   │        │
    │  └──────────────┘          └─────────────┘        │
    └────────────────────────────────────────────────────┘
```

## Component Details

### 1. Client Application

**Purpose**: Desktop application providing user interface and audio processing.

**Key Components**:

- **GUI Layer**: 
  - Technology: Electron + React or Qt
  - Responsibilities: User interaction, frequency management, settings
  
- **Audio Engine**:
  - Technology: Native C++ with bindings (PortAudio + libopus)
  - Responsibilities: 
    - Capture audio from input device
    - Encode with Opus codec
    - Decode received audio
    - Mix multiple frequency streams
    - Output to audio device
  
- **Network Layer**:
  - WebSocket connection to Control Service
  - UDP socket to Voice Service
  - Packet serialization/deserialization
  
- **Input Handler**:
  - Global hotkey registration
  - PTT state management
  - Keyboard/mouse event handling

**Data Flow**:
```
[Microphone] → [Audio Capture] → [Opus Encode] → [UDP Packet] → [Voice Service]
                                                                            ↓
[Speaker] ← [Audio Output] ← [Mixer] ← [Opus Decode] ← [UDP Packet] ← [Voice Service]
```

**State Management**:
- Active frequencies
- Monitored frequencies
- PTT states per frequency
- Audio device configuration
- Hotkey bindings

### 2. Control Service

**Purpose**: Central coordination service for session management, authentication, and configuration.

**Technology Stack**:
- **Option A**: Node.js + Express + Socket.io
- **Option B**: Python + FastAPI + WebSocket
- **Option C**: Go + Gin + Gorilla WebSocket

**Components**:

```
┌──────────────────────────────────────────────┐
│          Control Service                     │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  API Gateway                           │ │
│  │  - Route handling                      │ │
│  │  - Request validation                  │ │
│  │  - Rate limiting                       │ │
│  └────────────┬───────────────────────────┘ │
│               │                              │
│  ┌────────────▼───────────────────────────┐ │
│  │  Authentication Middleware             │ │
│  │  - JWT validation                      │ │
│  │  - Session management                  │ │
│  └────────────┬───────────────────────────┘ │
│               │                              │
│  ┌────────────▼───────────────────────────┐ │
│  │  Business Logic Layer                  │ │
│  │  ┌──────────────┐  ┌─────────────────┐│ │
│  │  │ User Manager │  │ Frequency Mgr   ││ │
│  │  └──────────────┘  └─────────────────┘│ │
│  │  ┌──────────────┐  ┌─────────────────┐│ │
│  │  │ Session Mgr  │  │ Config Manager  ││ │
│  │  └──────────────┘  └─────────────────┘│ │
│  └────────────┬───────────────────────────┘ │
│               │                              │
│  ┌────────────▼───────────────────────────┐ │
│  │  Data Access Layer                     │ │
│  │  - PostgreSQL queries                  │ │
│  │  - Redis operations                    │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

**API Endpoints**:

```yaml
Authentication:
  POST /api/v1/auth/login:
    body: {username, password}
    response: {token, user_info}
  
  POST /api/v1/auth/logout:
    headers: {Authorization: Bearer <token>}
    response: {success}
  
  POST /api/v1/auth/refresh:
    body: {refresh_token}
    response: {token}

Frequencies:
  GET /api/v1/frequencies:
    response: [{frequency_id, frequency_int, display, description}]
  
  GET /api/v1/frequencies/{id}:
    response: {frequency_info, active_users}
  
  POST /api/v1/frequencies/tune:
    body: {frequency_id}
    response: {success}
  
  DELETE /api/v1/frequencies/{id}/leave:
    response: {success}

Users:
  GET /api/v1/users/online:
    response: [{user_id, username, frequencies}]
  
  GET /api/v1/users/me:
    response: {user_info, preferences}
  
  PUT /api/v1/users/me/preferences:
    body: {preferences}
    response: {success}

Session:
  GET /api/v1/session/info:
    response: {session_info, voice_endpoint}
  
  POST /api/v1/session/heartbeat:
    response: {acknowledged}

Settings:
  GET /api/v1/settings/hotkeys:
    response: [{hotkey_id, action, key_combination}]
  
  PUT /api/v1/settings/hotkeys:
    body: [{action, key_combination, frequency_id}]
    response: {success}

Devices:
  GET /api/v1/devices:
    response: {input_devices: [], output_devices: []}
```

**WebSocket Events**:

```yaml
Client → Server:
  - subscribe_frequency: {frequency_id}
  - unsubscribe_frequency: {frequency_id}
  - ptt_start: {frequency_id}
  - ptt_stop: {frequency_id}

Server → Client:
  - user_joined_frequency: {user_id, frequency_id}
  - user_left_frequency: {user_id, frequency_id}
  - user_transmitting: {user_id, frequency_id}
  - user_stopped_transmitting: {user_id, frequency_id}
  - frequency_updated: {frequency_id, changes}
  - connection_quality: {latency_ms, packet_loss}
```

### 3. Voice Service

**Purpose**: Real-time audio packet routing and delivery.

**Technology Stack**:
- **Preferred**: C++ or Rust (performance-critical)
- **Alternative**: Go (good balance of performance and development speed)

**Architecture**:

```
┌──────────────────────────────────────────────────────┐
│              Voice Service                            │
│                                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │  UDP Listener                                  │  │
│  │  - Binds to port range (50000-50099)          │  │
│  │  - Receives audio packets                     │  │
│  │  - Multi-threaded packet handling             │  │
│  └────────────┬───────────────────────────────────┘  │
│               │                                       │
│  ┌────────────▼───────────────────────────────────┐  │
│  │  Packet Processor                              │  │
│  │  - Validates packet format                     │  │
│  │  - Authenticates sender                        │  │
│  │  - Extracts frequency_id and user_id           │  │
│  │  - Handles sequence numbers                    │  │
│  └────────────┬───────────────────────────────────┘  │
│               │                                       │
│  ┌────────────▼───────────────────────────────────┐  │
│  │  Frequency Router                              │  │
│  │  - Maintains frequency → users mapping         │  │
│  │  - Routes packets to appropriate recipients    │  │
│  │  - Implements broadcast logic                  │  │
│  └────────────┬───────────────────────────────────┘  │
│               │                                       │
│  ┌────────────▼───────────────────────────────────┐  │
│  │  Packet Sender                                 │  │
│  │  - Buffers outgoing packets                    │  │
│  │  - Sends to client UDP endpoints               │  │
│  │  - Tracks sent packets for metrics             │  │
│  └────────────────────────────────────────────────┘  │
│                                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │  Session Manager                               │  │
│  │  - Validates session tokens (via Redis)        │  │
│  │  - Tracks active connections                   │  │
│  │  - Handles timeouts and disconnections         │  │
│  └────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────┘
```

**Packet Processing Flow**:

```
1. Receive UDP packet
   ↓
2. Parse header (version, sequence, timestamp, user_id, freq_id)
   ↓
3. Validate session token (check Redis)
   ↓
4. Lookup frequency room (Redis: frequency:{freq_id}:users)
   ↓
5. For each user in room (except sender):
   ↓
6. Clone packet, update headers
   ↓
7. Send to user's UDP endpoint
   ↓
8. Update metrics (Redis: counters)
```

**Performance Considerations**:

- **Thread Model**: One thread per CPU core for packet processing
- **Zero-Copy**: Use memory mapping where possible
- **Packet Pooling**: Reuse packet buffers to reduce allocations
- **Batching**: Process packets in batches for efficiency
- **Target Latency**: < 50ms server-side processing

### 4. Discord Service

**Purpose**: Provide Discord bot interface for system management.

**Technology Stack**:
- **Option A**: Discord.js (Node.js)
- **Option B**: discord.py (Python)

**Components**:

```
┌──────────────────────────────────────────────┐
│          Discord Service                     │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Discord Bot Client                    │ │
│  │  - Connects to Discord API             │ │
│  │  - Registers slash commands            │ │
│  │  - Handles events                      │ │
│  └────────────┬───────────────────────────┘ │
│               │                              │
│  ┌────────────▼───────────────────────────┐ │
│  │  Command Handler                       │ │
│  │  - /krt-freq commands                  │ │
│  │  - /krt-online                         │ │
│  │  - /krt-status                         │ │
│  └────────────┬───────────────────────────┘ │
│               │                              │
│  ┌────────────▼───────────────────────────┐ │
│  │  API Client                            │ │
│  │  - HTTP client for Control Service     │ │
│  │  - Authentication handling             │ │
│  │  - Request/response mapping            │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

**Command Implementations**:

```javascript
// Example: /krt-freq list
async function handleFreqList(interaction) {
    // 1. Call Control Service API
    const response = await fetch(`${CONTROL_API}/api/v1/frequencies`, {
        headers: { 'Authorization': `Bearer ${BOT_TOKEN}` }
    });
    const frequencies = await response.json();
    
    // 2. Format for Discord
    const embed = new Discord.MessageEmbed()
        .setTitle('Available Frequencies')
        .setDescription(frequencies.map(f => 
            `**${f.frequency_display}** - ${f.description}`
        ).join('\n'));
    
    // 3. Reply to interaction
    await interaction.reply({ embeds: [embed] });
}
```

### 5. Data Layer

#### PostgreSQL Database

**Schema Organization**:

```
Schema: public
  Tables:
    - users
    - frequencies
    - user_frequencies (join table)
    - sessions
    - transmission_logs
    - user_hotkeys
    - user_audio_devices
    - permissions (future)
    - audit_logs (future)
```

**Connection Management**:

```yaml
Connection Pool:
  min_connections: 5
  max_connections: 50
  acquire_timeout: 10s
  idle_timeout: 600s
  max_lifetime: 3600s

Replication:
  primary: Read/Write
  replica_1: Read-only
  replica_2: Read-only
  
Backup Strategy:
  - Daily full backup
  - Hourly incremental backup
  - Point-in-time recovery enabled
  - Retention: 30 days
```

**Query Optimization**:

- Indexes on all foreign keys
- Composite indexes for common queries
- Partitioning for large tables (transmission_logs by date)
- Materialized views for analytics

#### Redis Cache

**Key Namespaces**:

```
session:{user_id}                              # User session data
frequency:{frequency_id}:users                 # Set of user IDs on frequency
user:{user_id}:frequencies                     # Set of frequency IDs for user
ptt:{frequency_id}:{user_id}                   # PTT state
stats:packets:{date}                           # Daily packet counter
stats:transmissions:{frequency_id}:{date}      # Daily transmission counter
config:frequencies                             # Cached frequency list
```

**Data Structures**:

```redis
# Session data
SET session:123 '{"token":"abc...", "connected_at":1234567890, "ip":"1.2.3.4"}' EX 1800

# Frequency membership (Set)
SADD frequency:121500:users 123 456 789

# User frequencies (Set)
SADD user:123:frequencies 121500 118100

# PTT state (String with JSON)
SETEX ptt:121500:123 10 '{"transmitting":true, "started_at":1234567890}'

# Counters (String)
INCR stats:packets:2026-02-07
INCRBY stats:transmissions:121500:2026-02-07 1
```

**Persistence**:

```yaml
RDB (Snapshot):
  - Every 15 minutes if >= 1 key changed
  - Backup to disk
  
AOF (Append-Only File):
  - fsync every second
  - Rewrite automatically
  
Replication:
  - Master-replica setup
  - Automatic failover with Sentinel
```

## Network Architecture

### Ports and Protocols

```
Service           Port(s)          Protocol    Purpose
─────────────────────────────────────────────────────────────
Control Service   443 (TLS)        HTTPS       REST API
Control Service   443 (TLS)        WSS         WebSocket
Voice Service     50000-50099      UDP         Audio packets
Discord Bot       443 (TLS)        HTTPS       Discord API
PostgreSQL        5432 (internal)  TCP         Database
Redis             6379 (internal)  TCP         Cache
```

### Security Zones

```
┌──────────────────────────────────────────────────┐
│  Internet (Public)                               │
│                                                  │
│  Clients, Discord Bot                           │
└────────────────┬─────────────────────────────────┘
                 │
                 │ Firewall
                 │
┌────────────────▼─────────────────────────────────┐
│  DMZ (Semi-trusted)                              │
│                                                  │
│  Load Balancer, API Gateway                     │
│  Control Service (HTTPS/WSS)                    │
│  Voice Service (UDP)                            │
└────────────────┬─────────────────────────────────┘
                 │
                 │ Firewall
                 │
┌────────────────▼─────────────────────────────────┐
│  Internal (Trusted)                              │
│                                                  │
│  PostgreSQL, Redis                              │
│  Monitoring, Logging                            │
└──────────────────────────────────────────────────┘
```

## Deployment Architecture

### Container Deployment (Docker)

```yaml
version: '3.8'

services:
  control-service:
    image: krt-comms/control-service:latest
    ports:
      - "443:443"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure

  voice-service:
    image: krt-comms/voice-service:latest
    ports:
      - "50000-50099:50000-50099/udp"
    environment:
      - REDIS_HOST=redis
    depends_on:
      - redis
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  discord-service:
    image: krt-comms/discord-service:latest
    environment:
      - DISCORD_TOKEN=${DISCORD_TOKEN}
      - CONTROL_API_URL=https://control-service
    depends_on:
      - control-service
    deploy:
      replicas: 1

  postgres:
    image: postgres:15-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    deploy:
      replicas: 1

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    deploy:
      replicas: 1

volumes:
  postgres-data:
  redis-data:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: control-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: control-service
  template:
    metadata:
      labels:
        app: control-service
    spec:
      containers:
      - name: control-service
        image: krt-comms/control-service:latest
        ports:
        - containerPort: 443
        env:
        - name: DB_HOST
          value: postgres-service
        - name: REDIS_HOST
          value: redis-service
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

## Monitoring and Observability

### Metrics Collection

**Tools**: Prometheus + Grafana

**Key Metrics**:

```yaml
Application Metrics:
  - http_requests_total (counter)
  - http_request_duration_seconds (histogram)
  - websocket_connections_active (gauge)
  - audio_packets_sent_total (counter)
  - audio_packets_received_total (counter)
  - audio_packet_loss_rate (gauge)
  - frequency_users_count (gauge)
  - ptt_activations_total (counter)

System Metrics:
  - cpu_usage_percent (gauge)
  - memory_usage_bytes (gauge)
  - disk_io_bytes (counter)
  - network_io_bytes (counter)

Database Metrics:
  - postgres_connections_active (gauge)
  - postgres_query_duration_seconds (histogram)
  - redis_commands_total (counter)
  - redis_memory_usage_bytes (gauge)
```

### Logging

**Tools**: ELK Stack (Elasticsearch, Logstash, Kibana) or Loki

**Log Levels**:
- ERROR: System errors, exceptions
- WARN: Unusual conditions, potential issues
- INFO: Important business events
- DEBUG: Detailed diagnostic information

**Structured Logging**:

```json
{
  "timestamp": "2026-02-07T12:34:56.789Z",
  "level": "INFO",
  "service": "control-service",
  "user_id": 123,
  "action": "frequency_tune",
  "frequency_id": 121500,
  "duration_ms": 45,
  "status": "success"
}
```

### Tracing

**Tool**: Jaeger or Zipkin

**Trace Spans**:
- API request handling
- Database queries
- Redis operations
- External API calls (Discord)
- Audio packet routing

## Scalability Considerations

### Horizontal Scaling

- **Control Service**: Stateless, scale with load balancer
- **Voice Service**: Shard by frequency range
- **Discord Service**: Single instance (bot limitation)
- **PostgreSQL**: Read replicas for queries
- **Redis**: Redis Cluster for large datasets

### Load Balancing

```
             [Load Balancer]
                   │
        ┌──────────┼──────────┐
        │          │          │
   [Instance 1] [Instance 2] [Instance 3]
```

**Algorithm**: Round-robin with health checks

**Health Check**: GET /health endpoint

### Caching Strategy

1. **Frequency List**: Cache for 5 minutes
2. **User Profiles**: Cache for 1 hour
3. **Session Data**: Always from Redis (source of truth)
4. **Device List**: No caching (changes frequently)

## Disaster Recovery

### Backup Strategy

```yaml
PostgreSQL:
  - Full backup: Daily at 02:00 UTC
  - Incremental backup: Every 6 hours
  - WAL archiving: Continuous
  - Retention: 30 days
  - Offsite backup: S3 or equivalent

Redis:
  - RDB snapshot: Every 15 minutes
  - AOF: Every second
  - Retention: 7 days
  - Offsite backup: Daily
```

### Recovery Procedures

```yaml
PostgreSQL Recovery:
  1. Stop application services
  2. Restore from latest backup
  3. Apply WAL archives (point-in-time)
  4. Verify data integrity
  5. Restart services
  RTO: 30 minutes
  RPO: 15 minutes

Redis Recovery:
  1. Promote replica to master (if available)
  2. Or restore from RDB/AOF
  3. Update application configuration
  4. Restart services
  RTO: 5 minutes (with replica)
  RPO: 1 second (with AOF)
```

## Development Workflow

### Local Development Setup

```bash
# 1. Clone repository
git clone https://github.com/org/krt-comms.git
cd krt-comms

# 2. Start infrastructure
docker-compose -f docker-compose.dev.yml up -d

# 3. Run database migrations
npm run migrate

# 4. Start services
cd services/control-service && npm run dev &
cd services/voice-service && cargo run &
cd services/discord-service && python main.py &

# 5. Start client application
cd client && npm run dev
```

### CI/CD Pipeline

```yaml
stages:
  - lint
  - test
  - build
  - deploy

lint:
  script:
    - npm run lint
    - cargo clippy

test:
  script:
    - npm run test
    - cargo test
    - pytest

build:
  script:
    - docker build -t krt-comms/control-service:$CI_COMMIT_SHA .
    - docker push krt-comms/control-service:$CI_COMMIT_SHA

deploy:
  script:
    - kubectl set image deployment/control-service control-service=krt-comms/control-service:$CI_COMMIT_SHA
    - kubectl rollout status deployment/control-service
```

---

## Conclusion

This architecture provides a scalable, maintainable foundation for KRT-Comms for Discord. Key design principles:

1. **Separation of Concerns**: Control and voice services are independent
2. **Scalability**: Horizontal scaling for all stateless components
3. **Reliability**: Redundancy, health checks, automatic recovery
4. **Performance**: Optimized audio pipeline, efficient packet routing
5. **Security**: Defense in depth, encrypted communications, authentication
6. **Observability**: Comprehensive logging, metrics, and tracing

**Next Steps**: See IMPLEMENTATION-GUIDE.md for development instructions.
