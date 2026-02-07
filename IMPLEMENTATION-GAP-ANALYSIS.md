# KRT-Comms for Discord - Implementation Gap Analysis

**Version:** 1.0  
**Date:** 2026-02-07  
**Purpose:** Identify gaps between current repository state and KRT-Comms specification

---

## Executive Summary

This document analyzes the current MediaStack repository against the KRT-Comms for Discord specification requirements. The repository currently contains Docker configurations for media server management and does NOT contain any KRT-Comms implementation code.

**Status**: No KRT-Comms implementation exists - full greenfield development required.

---

## Current Repository State

### What Exists

The repository currently contains:

1. **Media Server Infrastructure**:
   - Docker Compose configurations for Jellyfin, Plex, and related media services
   - VPN configurations (Gluetun)
   - Reverse proxy setup (Traefik)
   - Database services (PostgreSQL, Redis/Valkey)
   - Authentication (Authentik)

2. **Configuration Files**:
   - `.env` file for environment variables
   - Shell scripts for deployment
   - YAML configurations for various services

3. **Documentation**:
   - README with MediaStack setup instructions
   - Configuration guides for media services

### What Does NOT Exist

The repository does NOT contain any code related to:

- Voice communication systems
- Audio transport protocols
- Opus codec integration
- Push-to-talk functionality
- Frequency management
- Client desktop applications
- Voice service implementations
- Discord bot for KRT-Comms
- KRT-Comms specific database schemas

---

## Gap Analysis by Component

### 1. Audio Transport (UDP with Opus)

**Requirement**: UDP-based audio transport using Opus codec

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No UDP server implementation
- [ ] No Opus codec integration
- [ ] No audio packet format definition
- [ ] No packet routing logic
- [ ] No bandwidth management
- [ ] No packet loss handling

**Implementation Effort**: High (4-6 weeks)

**Dependencies**:
- libopus library
- UDP networking library
- Packet serialization framework

**Proposed Implementation**:
```
1. Create voice-service component (Rust or C++)
2. Integrate libopus for encode/decode
3. Define binary packet protocol
4. Implement UDP server with multi-threading
5. Add packet routing by frequency
6. Implement QoS and loss recovery
```

---

### 2. Frequency Integer Handling

**Requirement**: Represent frequencies as integers (e.g., 121500 for 121.500 MHz)

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No frequency data model
- [ ] No frequency database schema
- [ ] No frequency validation logic
- [ ] No frequency-to-display conversion
- [ ] No frequency categorization

**Implementation Effort**: Low (1 week)

**Proposed Implementation**:
```sql
-- Add to PostgreSQL schema
CREATE TABLE frequencies (
    frequency_id SERIAL PRIMARY KEY,
    frequency_int INTEGER NOT NULL UNIQUE,
    frequency_display VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed with common frequencies
INSERT INTO frequencies (frequency_int, frequency_display, description, category) VALUES
(121500, '121.500', 'Guard/Emergency', 'Emergency'),
(118100, '118.100', 'Ground Control', 'ATC'),
(119700, '119.700', 'Tower', 'ATC');
```

---

### 3. Client-Side Audio Mixing

**Requirement**: Client application must mix multiple frequency streams in real-time

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No client application
- [ ] No audio mixer implementation
- [ ] No multi-stream decoder
- [ ] No volume control per stream
- [ ] No priority-based mixing
- [ ] No AGC (Automatic Gain Control)

**Implementation Effort**: High (3-4 weeks)

**Dependencies**:
- Audio library (PortAudio or similar)
- Opus decoder library
- DSP (Digital Signal Processing) library

**Proposed Implementation**:
```cpp
// Pseudo-code
class AudioMixer {
private:
    std::map<int, OpusDecoder*> decoders;
    std::map<int, float> volumes;
    float masterVolume;
    
public:
    void addFrequency(int freqId, float volume);
    void removeFrequency(int freqId);
    void setVolume(int freqId, float volume);
    void mixAudio(float* outputBuffer, size_t frames);
};
```

---

### 4. Hotkeys and Push-to-Talk (PTT)

**Requirement**: Configurable hotkeys for PTT with multi-frequency support

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No hotkey registration system
- [ ] No global hotkey support (when app not focused)
- [ ] No PTT state management
- [ ] No hotkey conflict detection
- [ ] No hotkey persistence
- [ ] No UI for hotkey configuration

**Implementation Effort**: Medium (2-3 weeks)

**Dependencies**:
- Platform-specific hotkey library:
  - Windows: RegisterHotKey API
  - macOS: Carbon/Cocoa APIs
  - Linux: X11 or Wayland

**Proposed Implementation**:
```typescript
// Electron main process
import { globalShortcut } from 'electron';

class HotkeyManager {
    registerPTT(keyCombo: string, frequencyId: number) {
        globalShortcut.register(keyCombo, () => {
            this.startTransmit(frequencyId);
        });
    }
    
    unregisterAll() {
        globalShortcut.unregisterAll();
    }
}
```

---

### 5. Device Hot-Swap

**Requirement**: Change audio devices without restarting application

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No audio device enumeration
- [ ] No device change detection
- [ ] No graceful device switching
- [ ] No automatic fallback
- [ ] No device preference persistence

**Implementation Effort**: Medium (2 weeks)

**Proposed Implementation**:
```cpp
// Using PortAudio
class AudioDeviceManager {
    void enumerateDevices();
    void switchInputDevice(int deviceId);
    void switchOutputDevice(int deviceId);
    void onDeviceChange(callback);
};

// Graceful switching
void AudioDeviceManager::switchInputDevice(int deviceId) {
    // 1. Stop current stream
    Pa_StopStream(inputStream);
    
    // 2. Close stream
    Pa_CloseStream(inputStream);
    
    // 3. Open new stream with new device
    Pa_OpenStream(&inputStream, &inputParams, ...);
    
    // 4. Start new stream
    Pa_StartStream(inputStream);
    
    // 5. Persist preference
    savePreference(deviceId);
}
```

---

### 6. GUI Requirements

**Requirement**: Desktop application with frequency management, device selection, and status display

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No desktop application
- [ ] No GUI framework chosen
- [ ] No frequency list UI
- [ ] No device selector UI
- [ ] No PTT visual feedback
- [ ] No status bar
- [ ] No settings panel
- [ ] No accessibility features

**Implementation Effort**: High (6-8 weeks)

**Technology Options**:

| Technology | Pros | Cons | Effort |
|------------|------|------|--------|
| Electron + React | Web tech, cross-platform, rich ecosystem | Large bundle, high memory | Medium |
| Qt/C++ | Native, performant, mature | C++ complexity, steeper learning curve | High |
| Tauri + React | Smaller bundle than Electron, Rust backend | Newer, smaller ecosystem | Medium |

**Recommended**: Electron + React (familiar to web devs, good for MVP)

**Proposed Structure**:
```
client/
├── src/
│   ├── main/           # Electron main process
│   │   ├── index.ts
│   │   ├── audio/      # Audio engine
│   │   ├── network/    # Network layer
│   │   └── hotkeys/    # Hotkey handling
│   └── renderer/       # React UI
│       ├── App.tsx
│       ├── components/
│       │   ├── FrequencyList.tsx
│       │   ├── DeviceSelector.tsx
│       │   ├── StatusBar.tsx
│       │   └── Settings.tsx
│       └── services/   # API clients
├── package.json
└── webpack.config.js
```

---

### 7. Control and Voice Services

**Requirement**: Backend services for session management and audio routing

**Current State**: ⚠️ Partial infrastructure

**What Exists**:
- ✅ PostgreSQL already configured in MediaStack
- ✅ Redis (Valkey) already configured in MediaStack
- ✅ Docker Compose infrastructure

**Gaps**:
- [ ] No Control Service REST API
- [ ] No Control Service WebSocket support
- [ ] No Voice Service UDP server
- [ ] No authentication system for KRT-Comms
- [ ] No frequency management API
- [ ] No session management
- [ ] No KRT-Comms database schema

**Implementation Effort**: High (6-8 weeks)

**Proposed Approach**:

1. **Leverage Existing Infrastructure**:
   - Use existing PostgreSQL service
   - Use existing Redis/Valkey service
   - Add new services to docker-compose.yaml

2. **Add Control Service**:
```yaml
# Add to docker-compose.yaml
  krt-control-service:
    image: krt-comms/control-service:latest
    build: ./services/control-service
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgresql
      - REDIS_HOST=valkey
      - JWT_SECRET=${KRT_JWT_SECRET}
    depends_on:
      - postgresql
      - valkey
    networks:
      - mediastack
```

3. **Add Voice Service**:
```yaml
  krt-voice-service:
    image: krt-comms/voice-service:latest
    build: ./services/voice-service
    ports:
      - "50000-50010:50000-50010/udp"
    environment:
      - REDIS_HOST=valkey
    depends_on:
      - valkey
    networks:
      - mediastack
```

---

### 8. PostgreSQL and Redis Usage

**Requirement**: Use PostgreSQL for persistence, Redis for real-time state

**Current State**: ✅ Partially Available

**What Exists**:
- ✅ PostgreSQL container configured
- ✅ Redis (Valkey) container configured
- ✅ Connection infrastructure

**Gaps**:
- [ ] No KRT-Comms database schema
- [ ] No database migrations for KRT-Comms
- [ ] No Redis key namespace design
- [ ] No data access layer for KRT-Comms

**Implementation Effort**: Low-Medium (2 weeks)

**Proposed Schema Migration**:
```sql
-- migrations/001_krt_comms_initial_schema.sql

-- Users (extends existing or separate)
CREATE TABLE krt_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    discord_id VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Frequencies
CREATE TABLE krt_frequencies (
    frequency_id SERIAL PRIMARY KEY,
    frequency_int INTEGER NOT NULL UNIQUE,
    frequency_display VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User-Frequency associations
CREATE TABLE krt_user_frequencies (
    subscription_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES krt_users(user_id) ON DELETE CASCADE,
    frequency_id INTEGER REFERENCES krt_frequencies(frequency_id) ON DELETE CASCADE,
    is_monitoring BOOLEAN DEFAULT true,
    volume_level FLOAT DEFAULT 1.0,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, frequency_id)
);

-- Hotkeys
CREATE TABLE krt_user_hotkeys (
    hotkey_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES krt_users(user_id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    key_combination VARCHAR(100) NOT NULL,
    frequency_id INTEGER REFERENCES krt_frequencies(frequency_id),
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions
CREATE TABLE krt_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES krt_users(user_id),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_heartbeat TIMESTAMP,
    ended_at TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Transmission logs
CREATE TABLE krt_transmission_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES krt_users(user_id),
    frequency_id INTEGER REFERENCES krt_frequencies(frequency_id),
    started_at TIMESTAMP NOT NULL,
    duration_ms INTEGER NOT NULL,
    packet_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_sessions_user ON krt_sessions(user_id);
CREATE INDEX idx_sessions_token ON krt_sessions(session_token);
CREATE INDEX idx_transmission_logs_user ON krt_transmission_logs(user_id);
CREATE INDEX idx_transmission_logs_freq ON krt_transmission_logs(frequency_id);
CREATE INDEX idx_transmission_logs_started ON krt_transmission_logs(started_at);
```

**Redis Namespace Design**:
```
krt:session:{user_id}                          # Session data
krt:frequency:{frequency_id}:users             # Active users on frequency
krt:user:{user_id}:frequencies                 # User's active frequencies
krt:ptt:{frequency_id}:{user_id}               # PTT state
krt:stats:packets:{date}                       # Packet counters
```

---

### 9. Discord Bot Commands

**Requirement**: Discord bot for frequency management

**Current State**: ❌ Not implemented

**Gaps**:
- [ ] No Discord bot application
- [ ] No bot registration on Discord
- [ ] No slash command definitions
- [ ] No command handlers
- [ ] No integration with Control Service

**Implementation Effort**: Medium (3 weeks)

**Proposed Implementation**:

1. **Bot Setup**:
```javascript
// services/discord-service/src/index.js
const { Client, GatewayIntentBits, REST, Routes } = require('discord.js');

const client = new Client({
    intents: [GatewayIntentBits.Guilds]
});

// Register slash commands
const commands = [
    {
        name: 'krt-freq',
        description: 'Manage KRT-Comms frequencies',
        options: [
            {
                name: 'list',
                description: 'List available frequencies',
                type: 1  // SUB_COMMAND
            },
            {
                name: 'info',
                description: 'Get info about a frequency',
                type: 1,
                options: [{
                    name: 'frequency',
                    description: 'Frequency (e.g., 121.500)',
                    type: 3,  // STRING
                    required: true
                }]
            },
            {
                name: 'tune',
                description: 'Tune to a frequency',
                type: 1,
                options: [{
                    name: 'frequency',
                    description: 'Frequency to tune',
                    type: 3,
                    required: true
                }]
            }
        ]
    },
    {
        name: 'krt-online',
        description: 'Show users currently online'
    },
    {
        name: 'krt-status',
        description: 'Show KRT-Comms server status'
    }
];

client.on('ready', () => {
    console.log(`Logged in as ${client.user.tag}`);
});

client.on('interactionCreate', async interaction => {
    if (!interaction.isChatInputCommand()) return;
    
    if (interaction.commandName === 'krt-freq') {
        await handleFreqCommand(interaction);
    } else if (interaction.commandName === 'krt-online') {
        await handleOnlineCommand(interaction);
    } else if (interaction.commandName === 'krt-status') {
        await handleStatusCommand(interaction);
    }
});

client.login(process.env.DISCORD_TOKEN);
```

2. **Docker Integration**:
```yaml
# Add to docker-compose.yaml
  krt-discord-bot:
    image: krt-comms/discord-bot:latest
    build: ./services/discord-service
    environment:
      - DISCORD_TOKEN=${KRT_DISCORD_TOKEN}
      - DISCORD_APP_ID=${KRT_DISCORD_APP_ID}
      - CONTROL_SERVICE_URL=http://krt-control-service:3000
      - CONTROL_SERVICE_TOKEN=${KRT_CONTROL_API_TOKEN}
    depends_on:
      - krt-control-service
    networks:
      - mediastack
    restart: unless-stopped
```

---

## Infrastructure Leveraging

### Reusable Components from MediaStack

The following can be leveraged from the existing MediaStack setup:

| Component | Current Use | KRT-Comms Use | Integration |
|-----------|-------------|---------------|-------------|
| PostgreSQL | Media metadata | User/frequency data | Add KRT schema |
| Redis/Valkey | Caching | Real-time state | Add KRT namespaces |
| Traefik | Reverse proxy | Control Service proxy | Add routes |
| Authentik | SSO for media apps | Optional user auth | Configure provider |
| Docker Compose | Container orchestration | Add KRT services | Extend YAML |

**Benefits**:
- ✅ Reduce infrastructure setup time
- ✅ Leverage existing database/cache
- ✅ Consistent deployment methodology
- ✅ Shared monitoring/logging

**Considerations**:
- ⚠️ Keep KRT-Comms data isolated (separate schemas/namespaces)
- ⚠️ May want separate deployment for production
- ⚠️ MediaStack users != KRT-Comms users (different auth)

---

## Implementation Priority

### Phase 1: Foundation (Weeks 1-4) - CRITICAL

**Priority**: 🔴 Critical

1. [ ] Design and implement database schema
2. [ ] Set up Control Service skeleton (REST API)
3. [ ] Implement authentication and session management
4. [ ] Create basic frequency management API
5. [ ] Set up Redis state management

**Deliverable**: Working Control Service with authentication

---

### Phase 2: Voice Transport (Weeks 5-8) - CRITICAL

**Priority**: 🔴 Critical

1. [ ] Implement Voice Service UDP server
2. [ ] Integrate Opus codec
3. [ ] Implement packet routing by frequency
4. [ ] Add packet loss handling
5. [ ] Test audio quality and latency

**Deliverable**: Functional voice transport system

---

### Phase 3: Client Application (Weeks 9-14) - CRITICAL

**Priority**: 🔴 Critical

1. [ ] Set up Electron + React project
2. [ ] Implement GUI layouts
3. [ ] Integrate audio capture/playback
4. [ ] Implement audio mixer
5. [ ] Add PTT and hotkey support
6. [ ] Implement device management
7. [ ] Connect to Control and Voice services

**Deliverable**: Functional desktop client

---

### Phase 4: Integration (Weeks 15-17) - HIGH

**Priority**: 🟠 High

1. [ ] Implement Discord bot
2. [ ] Add Discord slash commands
3. [ ] Integrate bot with Control Service
4. [ ] End-to-end testing
5. [ ] Performance optimization

**Deliverable**: Complete system with Discord integration

---

### Phase 5: Polish (Weeks 18-20) - MEDIUM

**Priority**: 🟡 Medium

1. [ ] User testing and feedback
2. [ ] UI/UX improvements
3. [ ] Bug fixes
4. [ ] Documentation
5. [ ] Deployment guides

**Deliverable**: Production-ready system

---

## Technology Stack Recommendations

### Control Service
- **Language**: Node.js with TypeScript
- **Framework**: Express.js + Socket.io
- **Why**: Fast development, good async support, rich ecosystem
- **Alternative**: Python + FastAPI (if team prefers Python)

### Voice Service
- **Language**: Rust
- **Framework**: Tokio for async UDP
- **Why**: Performance, memory safety, excellent for network services
- **Alternative**: C++ (if team has C++ expertise)

### Client Application
- **Framework**: Electron + React
- **Audio**: PortAudio + opus.js (or native addon)
- **Why**: Cross-platform, web tech familiarity, rapid development
- **Alternative**: Qt (for native performance)

### Discord Bot
- **Language**: Node.js
- **Library**: Discord.js
- **Why**: Matches Control Service language, excellent Discord support

---

## Resource Requirements

### Development Team

```
Role                    Time Allocation    Duration
─────────────────────────────────────────────────────
Backend Developer       Full-time          20 weeks
Audio/Systems Dev       Full-time          16 weeks
Frontend Developer      Full-time          14 weeks
DevOps Engineer         Part-time (50%)    10 weeks
QA Engineer            Part-time (50%)    20 weeks
Technical Writer       Part-time (25%)    8 weeks
```

### Infrastructure

```
Environment    CPU    Memory    Storage    Est. Cost/Month
──────────────────────────────────────────────────────────
Development    8c     16GB      100GB      $50-100
Staging        16c    32GB      200GB      $200-300
Production     32c    64GB      500GB      $500-800
```

---

## Risk Assessment

### High Risks

1. **Audio Latency**
   - Risk: Latency exceeds 150ms target
   - Mitigation: Profile early, optimize packet routing, consider edge deployment

2. **Opus Integration Complexity**
   - Risk: Codec integration issues, quality problems
   - Mitigation: Prototype early, test multiple implementations

3. **Hotkey Conflicts**
   - Risk: System-wide hotkeys conflict with other apps
   - Mitigation: Robust conflict detection, fallback options

### Medium Risks

1. **Cross-Platform Audio**
   - Risk: Device enumeration differs by OS
   - Mitigation: Abstract device layer, test on all platforms early

2. **Discord API Changes**
   - Risk: Discord API updates break bot
   - Mitigation: Use official libraries, monitor Discord changelog

3. **Database Performance**
   - Risk: High-frequency updates cause DB bottleneck
   - Mitigation: Use Redis for hot data, async DB writes

---

## Success Criteria

### MVP Success Metrics

- [ ] Audio latency < 150ms (95th percentile)
- [ ] Support 50 concurrent users
- [ ] Audio quality (PESQ score > 3.5)
- [ ] Zero audio dropouts under normal conditions
- [ ] Client app starts in < 5 seconds
- [ ] Device switching in < 1 second
- [ ] 99.9% uptime for services
- [ ] All Discord commands functional
- [ ] Complete user documentation

---

## Next Steps

1. **Review and Approve Specification** (This document)
2. **Set Up Development Environment**
   - Create project repositories
   - Set up CI/CD pipelines
   - Provision development infrastructure

3. **Begin Phase 1 Implementation**
   - Database schema
   - Control Service
   - Basic authentication

4. **Weekly Progress Reviews**
   - Track against timeline
   - Adjust scope as needed
   - Risk mitigation

---

## Conclusion

The MediaStack repository provides a solid Docker infrastructure foundation that can be leveraged for KRT-Comms deployment, but **no KRT-Comms functionality currently exists**. The project requires:

- **4-5 months** of full-time development
- **3-4 developers** (backend, audio/systems, frontend)
- Significant new code across client, services, and integration layers

The existing PostgreSQL and Redis infrastructure can be reused, but all KRT-Comms specific components must be built from scratch.

**Recommendation**: Proceed with phased development approach, starting with backend services, then voice transport, then client application.

---

**Document Status**: Draft for Review  
**Next Review**: 2026-02-14  
**Owner**: Technical Architecture Team
