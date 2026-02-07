# KRT-Comms for Discord Specification

**Version:** 1.0  
**Last Updated:** 2026-02-07  
**Status:** Initial Release

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Core Requirements](#core-requirements)
4. [Audio Transport](#audio-transport)
5. [Frequency Management](#frequency-management)
6. [Client-Side Audio Mixing](#client-side-audio-mixing)
7. [Input Controls](#input-controls)
8. [Device Management](#device-management)
9. [GUI Requirements](#gui-requirements)
10. [Service Architecture](#service-architecture)
11. [Database Layer](#database-layer)
12. [Discord Bot Integration](#discord-bot-integration)
13. [Non-Goals and MVP Scope](#non-goals-and-mvp-scope)
14. [Security Considerations](#security-considerations)

---

## Overview

KRT-Comms for Discord is a specialized voice communication system designed to provide push-to-talk (PTT) functionality with multiple frequency support, integrated with Discord for coordination and control. The system enables users to communicate over different frequency channels using high-quality audio codec while maintaining compatibility with Discord for text-based coordination.

### Key Features

- **Multi-frequency voice communication** with PTT controls
- **UDP-based audio transport** using Opus codec for low latency
- **Client-side audio mixing** for multiple simultaneous frequency monitoring
- **Hot-swappable audio devices** without service interruption
- **Discord bot integration** for frequency management and coordination
- **PostgreSQL database** for persistent data storage
- **Redis caching** for real-time state management

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Application                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  GUI Layer   │  │ Audio Engine │  │ Input Handler│      │
│  │              │  │  (Opus)      │  │  (PTT/Keys)  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼────────┐       ┌───────▼────────┐
        │ Control Service│       │  Voice Service │
        │   (REST API)   │       │   (UDP Audio)  │
        │                │       │                │
        └───────┬────────┘       └───────┬────────┘
                │                        │
        ┌───────▼────────────────────────▼────────┐
        │         Backend Services                 │
        │  ┌──────────┐        ┌──────────┐       │
        │  │PostgreSQL│        │  Redis   │       │
        │  │ Database │        │  Cache   │       │
        │  └──────────┘        └──────────┘       │
        └────────────┬─────────────────────────────┘
                     │
             ┌───────▼────────┐
             │  Discord Bot   │
             │   Integration  │
             └────────────────┘
```

### Component Interaction

1. **Client Application**: Desktop/mobile application with GUI and audio processing
2. **Control Service**: HTTP/WebSocket service for session management and configuration
3. **Voice Service**: UDP-based audio transport service
4. **PostgreSQL**: Stores users, frequencies, permissions, and session history
5. **Redis**: Manages real-time state, active connections, and frequency assignments
6. **Discord Bot**: Provides command interface for frequency management

---

## Core Requirements

### Functional Requirements

1. **FR-1**: System MUST support multiple simultaneous frequency channels
2. **FR-2**: System MUST provide push-to-talk (PTT) functionality
3. **FR-3**: System MUST support configurable hotkey bindings
4. **FR-4**: System MUST allow monitoring multiple frequencies simultaneously
5. **FR-5**: System MUST support hot-swapping of audio input/output devices
6. **FR-6**: System MUST integrate with Discord for command and control
7. **FR-7**: System MUST persist user preferences and frequency configurations
8. **FR-8**: System MUST support frequency integer identification (e.g., 121.500, 243.000)

### Non-Functional Requirements

1. **NFR-1**: Audio latency MUST be less than 150ms end-to-end
2. **NFR-2**: System MUST support at least 50 concurrent users per server
3. **NFR-3**: Audio quality MUST use Opus codec at minimum 32kbps bitrate
4. **NFR-4**: System MUST recover gracefully from network interruptions
5. **NFR-5**: GUI MUST be responsive and support keyboard navigation

---

## Audio Transport

### Transport Protocol

The system uses **UDP** for audio transport to minimize latency. Each audio packet contains:

- **Opus-encoded audio data**: Variable bitrate 16-48 kbps
- **Sequence number**: For packet ordering and loss detection
- **Timestamp**: For synchronization
- **Frequency identifier**: Integer representing the frequency channel
- **User identifier**: Source of the audio

### Packet Format

```
┌─────────────────────────────────────────────────────┐
│ Header (32 bytes)                                    │
├──────────────┬──────────────┬──────────────┬────────┤
│ Version (4B) │ SeqNum (8B)  │ Timestamp(8B)│UID(8B) │
├──────────────┴──────────────┴──────────────┴────────┤
│ FreqID (4B)  │ PayloadLen(4B)│ Reserved(8B)         │
├─────────────────────────────────────────────────────┤
│ Opus Payload (variable, max 1200 bytes)             │
└─────────────────────────────────────────────────────┘
```

### Opus Configuration

- **Sample Rate**: 48 kHz
- **Frame Size**: 20ms (960 samples)
- **Channels**: Mono
- **Bitrate**: Adaptive 16-48 kbps
- **Complexity**: 10 (highest quality)
- **Packet Loss Concealment**: Enabled

### Connection Management

1. **Session Establishment**:
   - Client authenticates with Control Service
   - Receives UDP endpoint and session token
   - Establishes UDP connection with Voice Service
   - Sends heartbeat packets every 5 seconds

2. **Keep-Alive**:
   - UDP heartbeat every 5 seconds
   - Session timeout after 30 seconds of inactivity
   - Automatic reconnection on connection loss

---

## Frequency Management

### Frequency Representation

Frequencies are represented as **integers** to avoid floating-point precision issues:

- **Format**: Integer value representing frequency in kHz
- **Example**: `121500` represents 121.500 MHz
- **Range**: 118000 - 137000 (for aviation VHF)
- **Alternative Ranges**: Configurable for different use cases

### Frequency Database Schema

```sql
CREATE TABLE frequencies (
    frequency_id SERIAL PRIMARY KEY,
    frequency_int INTEGER NOT NULL UNIQUE,
    frequency_display VARCHAR(20) NOT NULL,  -- e.g., "121.500"
    description VARCHAR(255),
    category VARCHAR(50),                    -- e.g., "ATC", "Ground", "Emergency"
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_frequencies_int ON frequencies(frequency_int);
CREATE INDEX idx_frequencies_category ON frequencies(category);
```

### Frequency Operations

1. **Tune to Frequency**: Client requests to monitor specific frequency
2. **Transmit on Frequency**: Client activates PTT for specific frequency
3. **Monitor Multiple**: Client can listen to multiple frequencies simultaneously
4. **Frequency Scanning**: Optional auto-scan feature (future enhancement)

---

## Client-Side Audio Mixing

### Mixing Architecture

The client performs **real-time audio mixing** of multiple frequency streams:

```
┌────────────────────────────────────────────────────┐
│           Audio Mixer (Client-Side)                │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ Freq 1   │  │ Freq 2   │  │ Freq N   │         │
│  │ Decoder  │  │ Decoder  │  │ Decoder  │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       │             │             │                │
│       │  ┌──────────▼─────────┐   │                │
│       └──► Volume Adjuster    ◄───┘                │
│          └──────────┬─────────┘                    │
│                     │                               │
│          ┌──────────▼─────────┐                    │
│          │   Master Mixer     │                    │
│          └──────────┬─────────┘                    │
│                     │                               │
│          ┌──────────▼─────────┐                    │
│          │  Audio Output      │                    │
│          └────────────────────┘                    │
└────────────────────────────────────────────────────┘
```

### Mixing Rules

1. **Priority System**:
   - Emergency frequencies (e.g., 243.000) have highest priority
   - Active transmit frequency has high priority
   - Other monitored frequencies mixed at lower volume

2. **Volume Management**:
   - Each frequency has individual volume control
   - Master volume applies to mixed output
   - Automatic gain control (AGC) prevents clipping

3. **Audio Processing**:
   - Each Opus stream decoded independently
   - Resampling if needed (all to 48 kHz)
   - Mixed in 32-bit float to prevent overflow
   - Final output converted to 16-bit PCM

### Implementation Notes

```javascript
// Pseudo-code for mixing
class AudioMixer {
    constructor() {
        this.streams = new Map(); // frequency_id -> AudioStream
        this.masterVolume = 1.0;
    }
    
    addStream(frequencyId, opusStream) {
        const decoder = new OpusDecoder(48000, 1);
        this.streams.set(frequencyId, {
            decoder: decoder,
            stream: opusStream,
            volume: 1.0,
            priority: this.getPriority(frequencyId)
        });
    }
    
    mixAudio(outputBuffer) {
        outputBuffer.fill(0);
        
        // Sort streams by priority
        const sorted = Array.from(this.streams.values())
            .sort((a, b) => b.priority - a.priority);
        
        // Mix each stream
        for (const stream of sorted) {
            const decoded = stream.decoder.decode(stream.buffer);
            const scaled = this.applyVolume(decoded, stream.volume);
            this.addToBuffer(outputBuffer, scaled);
        }
        
        // Apply master volume and AGC
        this.applyMasterVolume(outputBuffer, this.masterVolume);
        this.applyAGC(outputBuffer);
    }
}
```

---

## Input Controls

### Push-to-Talk (PTT)

1. **Activation Methods**:
   - Hardware button/pedal
   - Keyboard hotkey
   - On-screen button (touch/click)
   - Voice activation (optional, future)

2. **PTT States**:
   - **Idle**: Not transmitting, monitoring frequencies
   - **Active**: Transmitting on selected frequency
   - **Locked**: PTT locked on (toggle mode)

3. **Multi-Frequency PTT**:
   - Each frequency can have dedicated PTT hotkey
   - Default hotkey transmits on primary frequency
   - Modifier keys select alternate frequencies (e.g., Ctrl+PTT for frequency 2)

### Hotkey Configuration

```sql
CREATE TABLE user_hotkeys (
    hotkey_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    action VARCHAR(50) NOT NULL,           -- e.g., "PTT", "MUTE", "TUNE_FREQ"
    key_combination VARCHAR(100) NOT NULL, -- e.g., "Ctrl+Shift+T"
    frequency_id INTEGER REFERENCES frequencies(frequency_id),
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Hotkey Implementation Requirements

1. **Global Hotkeys**: Must work when application is not focused
2. **Conflict Detection**: Warn user of conflicts with system hotkeys
3. **Customization**: Full keyboard and mouse button support
4. **Profiles**: Support multiple hotkey profiles (e.g., "Gaming", "Work")

---

## Device Management

### Hot-Swap Support

The system MUST support changing audio devices without restart:

1. **Device Enumeration**:
   - List available input/output devices
   - Detect device addition/removal
   - Show device capabilities (sample rate, channels)

2. **Graceful Switching**:
   - Stop current audio stream
   - Reinitialize with new device
   - Resume audio processing
   - Preserve audio buffer state

3. **Error Handling**:
   - Detect device disconnection
   - Attempt automatic fallback to default device
   - Notify user of device issues
   - Allow manual device selection

### Device Configuration Storage

```sql
CREATE TABLE user_audio_devices (
    device_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    device_type VARCHAR(20) NOT NULL,      -- 'input' or 'output'
    device_name VARCHAR(255) NOT NULL,
    device_identifier VARCHAR(255),         -- System device ID
    is_default BOOLEAN DEFAULT false,
    last_used TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Implementation Requirements

1. **Platform Support**:
   - Windows: WASAPI or DirectSound
   - macOS: CoreAudio
   - Linux: PulseAudio or ALSA

2. **Auto-Selection**:
   - Remember last used device per user
   - Auto-select when previously used device reconnects
   - Fall back to system default if preferred unavailable

---

## GUI Requirements

### Main Application Window

```
┌────────────────────────────────────────────────────────┐
│ KRT-Comms                                    [_][□][X] │
├────────────────────────────────────────────────────────┤
│ File  Edit  View  Frequencies  Settings  Help         │
├────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐  │
│  │ Active Frequencies                              │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ [●] 121.500  Tower         [TX] [MON] [━━━━━━] │  │
│  │ [ ] 118.100  Ground        [TX] [MON] [━━━━━─] │  │
│  │ [ ] 243.000  Emergency     [TX] [MON] [━━━━━━] │  │
│  │                                    [+ Add Freq] │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Audio Devices                                   │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Input:  [Headset Microphone          ▼]        │  │
│  │ Output: [Headset Speakers            ▼]        │  │
│  │ Master Volume: [━━━━━━━━━━━━━━━━━━━─] 85%      │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Status                                          │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ ● Connected  |  3 users online  |  Latency:45ms│  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### GUI Components

1. **Frequency List**:
   - Shows active monitored frequencies
   - Visual indicator for active frequency
   - TX button per frequency
   - MON (monitor) toggle per frequency
   - Volume slider per frequency
   - Drag-to-reorder frequencies

2. **Audio Device Selector**:
   - Dropdown for input device
   - Dropdown for output device
   - Master volume control
   - Mute buttons

3. **Status Bar**:
   - Connection status indicator
   - Active users count
   - Network latency display
   - Transmit indicator (PTT active)

4. **Settings Panel** (separate window):
   - Hotkey configuration
   - Audio quality settings
   - Network configuration
   - Discord integration settings

### Accessibility Requirements

1. **Keyboard Navigation**: Full keyboard control
2. **Screen Reader Support**: ARIA labels and descriptions
3. **High Contrast Mode**: Support system theme
4. **Font Scaling**: Respect system font size settings

---

## Service Architecture

### Control Service

**Responsibilities**:
- User authentication and session management
- Frequency assignment and permissions
- Configuration management
- REST API for client interactions
- WebSocket for real-time updates

**Technology Stack**:
- Language: Node.js, Python, or Go
- Framework: Express/FastAPI/Gin
- API: RESTful + WebSocket
- Auth: JWT tokens

**API Endpoints**:

```
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
GET    /api/v1/frequencies
POST   /api/v1/frequencies/tune
DELETE /api/v1/frequencies/leave
GET    /api/v1/users/online
GET    /api/v1/session/info
PUT    /api/v1/settings/hotkeys
GET    /api/v1/devices
```

### Voice Service

**Responsibilities**:
- UDP audio packet routing
- Opus codec handling (encode/decode)
- Bandwidth management
- Packet loss handling
- Multi-frequency routing

**Technology Stack**:
- Language: C++, Rust, or Go (performance critical)
- Protocol: UDP with custom binary protocol
- Codec: libopus

**Components**:

```
┌─────────────────────────────────────────┐
│         Voice Service                    │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  UDP Listener (Port 50000-50099)   │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │  Packet Router                     │ │
│  │  - Validates packets               │ │
│  │  - Routes by frequency             │ │
│  │  - Manages packet queues           │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │  Frequency Rooms                   │ │
│  │  - freq_121500: [user1, user2]     │ │
│  │  - freq_118100: [user3]            │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Database Layer

### PostgreSQL Schema

The system uses PostgreSQL for persistent data storage:

```sql
-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    discord_id VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Frequencies table (defined earlier)
CREATE TABLE frequencies (
    frequency_id SERIAL PRIMARY KEY,
    frequency_int INTEGER NOT NULL UNIQUE,
    frequency_display VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User frequency subscriptions
CREATE TABLE user_frequencies (
    subscription_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    frequency_id INTEGER REFERENCES frequencies(frequency_id) ON DELETE CASCADE,
    is_monitoring BOOLEAN DEFAULT true,
    volume_level FLOAT DEFAULT 1.0,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, frequency_id)
);

-- Session history
CREATE TABLE sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Transmission logs
CREATE TABLE transmission_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    frequency_id INTEGER REFERENCES frequencies(frequency_id),
    started_at TIMESTAMP NOT NULL,
    duration_ms INTEGER NOT NULL,
    packet_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transmission_logs_user ON transmission_logs(user_id);
CREATE INDEX idx_transmission_logs_freq ON transmission_logs(frequency_id);
CREATE INDEX idx_transmission_logs_started ON transmission_logs(started_at);
```

### Database Queries

**Performance Requirements**:
- User authentication: < 100ms
- Frequency list retrieval: < 50ms
- Session update: < 20ms

**Connection Pooling**:
- Min connections: 5
- Max connections: 50
- Idle timeout: 10 minutes

---

## Redis Integration

### Usage Patterns

Redis is used for **real-time state management**:

1. **Active Sessions**:
   ```
   Key: session:{user_id}
   Value: {session_token, connected_at, last_heartbeat, ip_address}
   TTL: 30 seconds (refreshed by heartbeat)
   ```

2. **Frequency Occupancy**:
   ```
   Key: frequency:{frequency_id}:users
   Type: Set
   Members: [user_id_1, user_id_2, ...]
   ```

3. **User Presence**:
   ```
   Key: user:{user_id}:frequencies
   Type: Set
   Members: [frequency_id_1, frequency_id_2, ...]
   ```

4. **PTT State**:
   ```
   Key: ptt:{frequency_id}:{user_id}
   Value: {transmitting: true, started_at: timestamp}
   TTL: 10 seconds
   ```

### Redis Commands Used

- `SETEX` - Set with expiration for session management
- `SADD/SREM` - Set operations for frequency membership
- `SMEMBERS` - Get all users on a frequency
- `EXPIRE` - Refresh TTL on heartbeat
- `DEL` - Clean up on disconnect

### Configuration

```yaml
redis:
  host: localhost
  port: 6379
  db: 0
  password: ${REDIS_PASSWORD}
  max_connections: 50
  connect_timeout: 5s
  read_timeout: 2s
  write_timeout: 2s
```

---

## Discord Bot Integration

### Bot Commands

The Discord bot provides the following slash commands:

```
/krt-freq list
  - Lists all available frequencies

/krt-freq info <frequency>
  - Shows details about a specific frequency
  - Displays current users on the frequency

/krt-freq tune <frequency>
  - Adds frequency to your monitoring list

/krt-freq leave <frequency>
  - Removes frequency from your monitoring list

/krt-online
  - Shows all users currently connected to KRT-Comms

/krt-status
  - Shows server status and statistics

/krt-help
  - Displays help information
```

### Discord Integration Architecture

```
┌─────────────────────────────────────────────────┐
│              Discord Bot                         │
│                                                  │
│  ┌───────────────────────────────────────────┐  │
│  │ Command Handler                           │  │
│  │  - Slash command registration             │  │
│  │  - Command parsing and validation         │  │
│  └───────────────┬───────────────────────────┘  │
│                  │                               │
│  ┌───────────────▼───────────────────────────┐  │
│  │ API Client                                │  │
│  │  - Calls Control Service REST API         │  │
│  │  - Manages authentication                 │  │
│  └───────────────┬───────────────────────────┘  │
│                  │                               │
└──────────────────┼───────────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │  Control Service   │
         │  (REST API)        │
         └────────────────────┘
```

### Discord Bot Implementation

**Technology**: Discord.js (Node.js) or discord.py (Python)

**Features**:
1. **User Linking**: Link Discord account to KRT-Comms account
2. **Notifications**: 
   - Alert when user joins monitored frequency
   - Emergency frequency alerts
3. **Status Updates**:
   - Show who's online
   - Display frequency occupancy
4. **Administrative Commands** (privileged users):
   - Add/remove frequencies
   - Manage user permissions
   - View system statistics

### Bot Configuration

```yaml
discord:
  bot_token: ${DISCORD_BOT_TOKEN}
  application_id: ${DISCORD_APP_ID}
  guild_id: ${DISCORD_GUILD_ID}
  command_prefix: "/krt-"
  admin_role_id: ${ADMIN_ROLE_ID}
  notification_channel: ${NOTIFICATION_CHANNEL_ID}
```

---

## Non-Goals and MVP Scope

### What is NOT Included (MVP)

1. **Discord Voice Integration**:
   - ❌ KRT-Comms does NOT use Discord voice channels
   - ❌ No integration with Discord voice API
   - ✅ Uses independent UDP audio transport
   - **Rationale**: Discord voice has limitations on latency and codec control

2. **Full-Duplex Communication**:
   - ❌ NOT supporting simultaneous transmit and receive on same frequency
   - ✅ Push-to-talk (half-duplex) only for MVP
   - **Rationale**: Simplifies audio pipeline and matches real-world radio behavior

3. **End-to-End Encryption**:
   - ❌ No E2E encryption in MVP
   - ✅ Transport layer security (TLS for control, optional DTLS for voice)
   - ⚠️ All audio transmitted in cleartext (Opus encoded, not encrypted)
   - **Rationale**: Adds complexity and latency; deferred to post-MVP

4. **Mobile Applications**:
   - ❌ Native iOS/Android apps not in MVP
   - ✅ Desktop applications (Windows, macOS, Linux) only
   - **Future**: Mobile support in later release

5. **Recording/Playback**:
   - ❌ No built-in recording of transmissions
   - ❌ No playback of historical audio
   - **Future**: May add in post-MVP

6. **Video Support**:
   - ❌ Audio only, no video capabilities

### What IS Included (MVP)

1. ✅ UDP audio transport with Opus codec
2. ✅ Multi-frequency monitoring and transmission
3. ✅ Push-to-talk with hotkey support
4. ✅ Client-side audio mixing
5. ✅ Hot-swappable audio devices
6. ✅ Discord bot for frequency management
7. ✅ PostgreSQL persistence
8. ✅ Redis for real-time state
9. ✅ Desktop GUI application
10. ✅ Basic user authentication

---

## Security Considerations

### Authentication

1. **User Authentication**:
   - JWT tokens for API authentication
   - Token refresh mechanism
   - Session timeout after 24 hours

2. **Voice Service Authentication**:
   - Session token passed in initial UDP handshake
   - Token validated against Redis session store
   - Disconnection on invalid token

### Network Security

1. **Control Service**:
   - HTTPS/WSS for all control communication
   - TLS 1.3 minimum
   - Certificate pinning recommended

2. **Voice Service**:
   - UDP packets not encrypted in MVP
   - Optional DTLS in future release
   - IP allowlist for server infrastructure

### Data Privacy

1. **User Data**:
   - Passwords hashed with bcrypt (cost factor 12)
   - Email addresses stored encrypted at rest
   - PII access logged

2. **Transmission Logs**:
   - Limited retention (30 days default)
   - User can request deletion
   - No audio content stored

### Rate Limiting

1. **API Endpoints**: 100 requests/minute per user
2. **Discord Bot**: Discord's built-in rate limits
3. **Voice Packets**: Max 50 packets/second per user

---

## Implementation Phases

### Phase 1: Core Infrastructure (Weeks 1-4)

- [ ] Set up PostgreSQL database schema
- [ ] Set up Redis instance
- [ ] Implement Control Service REST API
- [ ] Implement basic authentication

### Phase 2: Voice Transport (Weeks 5-8)

- [ ] Implement UDP voice service
- [ ] Integrate Opus codec
- [ ] Implement packet routing
- [ ] Test audio quality and latency

### Phase 3: Client Application (Weeks 9-14)

- [ ] Build GUI framework
- [ ] Implement audio engine
- [ ] Implement PTT and hotkeys
- [ ] Implement device hot-swap
- [ ] Client-side mixing

### Phase 4: Integration (Weeks 15-16)

- [ ] Discord bot implementation
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Documentation

### Phase 5: Beta Testing (Weeks 17-20)

- [ ] Limited user beta
- [ ] Bug fixes
- [ ] Usability improvements
- [ ] Preparation for release

---

## Appendix

### Glossary

- **PTT**: Push-to-Talk
- **Opus**: Audio codec designed for interactive speech and music transmission
- **UDP**: User Datagram Protocol, connectionless transport protocol
- **Frequency**: In this context, a virtual communication channel
- **Hot-swap**: Ability to change devices without restarting application

### References

1. Opus Codec Specification: https://opus-codec.org/docs/
2. WebRTC Audio Processing: https://webrtc.org/
3. Discord API Documentation: https://discord.com/developers/docs
4. PostgreSQL Documentation: https://www.postgresql.org/docs/
5. Redis Documentation: https://redis.io/documentation

---

**Document Control**

- **Created**: 2026-02-07
- **Author**: System Architecture Team
- **Review Status**: Draft
- **Next Review**: 2026-03-07
