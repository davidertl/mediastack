# KRT-Comms for Discord - Non-Goals and MVP Scope

**Version:** 1.0  
**Date:** 2026-02-07  
**Purpose:** Clearly define what IS and IS NOT included in the MVP release

---

## Document Purpose

This document serves as a definitive reference for stakeholders, developers, and users to understand the boundaries of the KRT-Comms for Discord MVP (Minimum Viable Product). It explicitly states what features are included, excluded, and deferred to future releases.

---

## What IS Included in MVP ✅

### Core Voice Communication

✅ **UDP-Based Audio Transport**
- Real-time audio transmission over UDP
- Low-latency architecture (target < 150ms end-to-end)
- Packet loss handling and recovery
- Session management and heartbeat

✅ **Opus Codec Integration**
- High-quality audio encoding/decoding
- Adaptive bitrate (16-48 kbps)
- 48 kHz sample rate
- Mono channel audio
- Packet loss concealment

✅ **Multi-Frequency Support**
- Multiple virtual frequency channels
- Frequency represented as integers (e.g., 121500 = 121.500 MHz)
- Users can monitor multiple frequencies simultaneously
- Independent volume control per frequency

### Client Application

✅ **Desktop Application (Windows, macOS, Linux)**
- Cross-platform desktop application
- Native-like performance
- Electron + React or similar framework

✅ **Push-to-Talk (PTT) Functionality**
- Hardware button/pedal support
- Keyboard hotkey support
- On-screen button option
- Half-duplex transmission (one direction at a time)

✅ **Configurable Hotkeys**
- User-configurable key bindings
- Global hotkeys (work when app not focused)
- Multiple hotkeys per frequency
- Hotkey conflict detection
- Persistent hotkey preferences

✅ **Client-Side Audio Mixing**
- Real-time mixing of multiple audio streams
- Individual volume control per frequency
- Master volume control
- Priority-based mixing (emergency frequencies louder)
- Automatic Gain Control (AGC) to prevent clipping

✅ **Hot-Swappable Audio Devices**
- Change input device without restart
- Change output device without restart
- Automatic device enumeration
- Device preference persistence
- Fallback to default on device disconnect

✅ **GUI Requirements**
- Frequency list display
- Active frequency indicators
- Audio device selectors
- Volume controls
- Status bar (connection, users, latency)
- Settings panel
- Basic keyboard navigation

### Backend Services

✅ **Control Service**
- RESTful API for configuration
- WebSocket for real-time updates
- User authentication (JWT)
- Session management
- Frequency management API
- User preferences storage

✅ **Voice Service**
- UDP server for audio packets
- Packet routing by frequency
- Session validation
- Bandwidth management
- Basic quality metrics

### Database and Caching

✅ **PostgreSQL for Persistence**
- User accounts and profiles
- Frequency definitions
- Hotkey configurations
- Audio device preferences
- Session history
- Transmission logs (basic)

✅ **Redis for Real-Time State**
- Active session management
- Frequency occupancy tracking
- PTT state management
- Real-time user presence
- Packet counters and statistics

### Discord Integration

✅ **Discord Bot Commands**
- `/krt-freq list` - List available frequencies
- `/krt-freq info <frequency>` - Show frequency details
- `/krt-freq tune <frequency>` - Tune to frequency
- `/krt-freq leave <frequency>` - Leave frequency
- `/krt-online` - Show online users
- `/krt-status` - Show system status
- `/krt-help` - Display help

✅ **Discord Account Linking**
- Link Discord account to KRT-Comms account
- Discord notifications for important events

### Security

✅ **Basic Authentication**
- Username/password authentication
- JWT token-based sessions
- Password hashing (bcrypt)
- Session timeout and refresh

✅ **Transport Security**
- TLS for Control Service (HTTPS/WSS)
- Optional DTLS for Voice Service (UDP encryption)

---

## What IS NOT Included in MVP ❌

### Explicitly Excluded Features

❌ **Discord Voice API Integration**
- **NOT using Discord voice channels**
- **NOT integrating with Discord voice API**
- KRT-Comms uses independent UDP transport
- **Rationale**: Discord voice has limitations on latency, codec control, and custom audio processing

❌ **Full-Duplex Communication**
- **NOT supporting simultaneous transmit and receive on same frequency**
- MVP is push-to-talk (half-duplex) only
- **Rationale**: Simplifies audio pipeline, matches real-world radio behavior, reduces complexity

❌ **End-to-End Encryption**
- **No E2E encryption in MVP**
- Transport layer security only (TLS/DTLS)
- Audio transmitted in Opus format but NOT encrypted end-to-end
- **Rationale**: Adds significant complexity, increases latency, can be added post-MVP
- **Security Note**: Audio packets are not encrypted beyond transport security

❌ **Mobile Applications (Native)**
- **No iOS app in MVP**
- **No Android app in MVP**
- Desktop applications only (Windows, macOS, Linux)
- **Rationale**: Resource constraints, different UX requirements
- **Future**: Mobile support in post-MVP phase

❌ **Recording and Playback**
- **No built-in transmission recording**
- **No playback of historical audio**
- **No archive/replay features**
- **Rationale**: Storage requirements, privacy concerns, complexity
- **Future**: May be added as optional feature

❌ **Video Support**
- **Audio only, no video transmission**
- **No screen sharing**
- **No camera support**
- **Rationale**: Out of scope for voice communication system

❌ **Advanced Audio Features**
- **No voice activation (VOX) in MVP**
- **No echo cancellation**
- **No noise suppression** (basic only via Opus)
- **No spatial audio / 3D audio**
- **No audio effects or filters**
- **Rationale**: MVP focuses on basic functionality

❌ **Advanced Network Features**
- **No adaptive jitter buffer tuning**
- **No advanced QoS/traffic shaping**
- **No automatic server selection**
- **No CDN distribution**
- **Rationale**: Can be added based on performance testing

❌ **Enterprise Features**
- **No LDAP/Active Directory integration**
- **No SAML/OAuth2 providers** (beyond Discord)
- **No detailed audit logging**
- **No compliance reporting**
- **Rationale**: MVP targets individual users, not enterprises

❌ **Advanced Discord Integration**
- **No voice state synchronization with Discord**
- **No automatic channel creation**
- **No role-based permissions from Discord**
- **No Discord rich presence**
- **Rationale**: Basic bot functionality sufficient for MVP

---

## Deferred to Post-MVP (Future Releases) 🔮

### Phase 2 Features (Post-Launch)

🔮 **Enhanced Security**
- End-to-end encryption
- Advanced authentication (SAML, LDAP)
- Two-factor authentication (2FA)
- Security audit logging

🔮 **Mobile Applications**
- Native iOS application
- Native Android application
- Mobile-optimized UI
- Background audio support

🔮 **Recording and Compliance**
- Optional transmission recording
- Audio archive and playback
- Compliance logging
- Legal hold features

🔮 **Advanced Audio**
- Voice activation (VOX)
- Echo cancellation
- Noise suppression/reduction
- Audio quality presets

🔮 **Team and Organization Features**
- Teams/groups management
- Role-based access control
- Organizational hierarchies
- Usage analytics and reporting

🔮 **Integration Ecosystem**
- REST API for third-party integrations
- Webhooks for events
- Plugin system
- Custom bot commands

🔮 **Performance Enhancements**
- Edge deployment for regional latency
- CDN for static assets
- Advanced QoS and traffic management
- Automatic server load balancing

---

## MVP Success Criteria

The MVP is considered successful when it meets these criteria:

### Technical Metrics

✅ **Performance**
- Audio latency < 150ms (95th percentile)
- Support 50 concurrent users per server instance
- 99.9% uptime for services
- < 1% packet loss under normal conditions

✅ **Quality**
- Audio quality PESQ score > 3.5
- No audio dropouts under normal conditions
- Zero critical security vulnerabilities

✅ **User Experience**
- Client application starts in < 5 seconds
- Device switching completes in < 1 second
- All core features functional
- Basic help documentation available

### Feature Completeness

✅ **Must Have (P0)**
- User authentication ✅
- Frequency tuning ✅
- PTT functionality ✅
- Audio transmission/reception ✅
- Multi-frequency monitoring ✅
- Discord bot basic commands ✅
- Hotkey configuration ✅
- Device selection ✅

⚠️ **Should Have (P1)** - Nice to have but not blocking
- Detailed transmission logs
- Advanced metrics dashboard
- User activity history
- Export/import settings

❌ **Could Have (P2)** - Explicitly deferred
- Recording features
- Mobile apps
- E2E encryption
- Advanced audio processing

---

## Scope Boundaries

### In Scope for MVP

1. **User Functionality**
   - Register account
   - Login/logout
   - Configure preferences
   - Join/leave frequencies
   - Transmit on frequency (PTT)
   - Monitor multiple frequencies
   - Adjust volume levels
   - Configure hotkeys
   - Select audio devices
   - Use Discord bot commands

2. **Administrative Functionality**
   - Manage frequencies (add/remove/modify)
   - View system status
   - View active users
   - Basic troubleshooting tools

3. **Technical Functionality**
   - Maintain session
   - Route audio packets
   - Handle disconnections gracefully
   - Persist user preferences
   - Cache active state

### Out of Scope for MVP

1. **Advanced User Features**
   - Custom frequency groups/presets
   - Frequency scanning
   - Audio effects
   - Voice activation

2. **Advanced Administrative Features**
   - User management dashboard
   - Detailed analytics
   - Billing/subscription management
   - API key management

3. **Integration Features**
   - Third-party integrations
   - Webhooks
   - Public API
   - Plugin system

---

## Decision Log

This section documents key architectural decisions and their rationale.

### Decision 1: No Discord Voice Integration

**Decision**: Do NOT use Discord voice channels or API  
**Date**: 2026-02-07  
**Rationale**:
- Discord voice has fixed codec settings
- Limited control over latency
- Cannot implement custom audio processing
- Cannot support multi-frequency model effectively

**Trade-offs**:
- ✅ Full control over audio pipeline
- ✅ Lower latency possible
- ✅ Custom features (multi-frequency mixing)
- ❌ Cannot leverage Discord's voice infrastructure
- ❌ Need to build and maintain own voice service

### Decision 2: Half-Duplex (PTT) Only for MVP

**Decision**: Push-to-talk only, no full-duplex  
**Date**: 2026-02-07  
**Rationale**:
- Simpler audio pipeline
- Matches real-world radio behavior
- Reduces CPU usage on client
- Avoids feedback issues

**Trade-offs**:
- ✅ Simpler implementation
- ✅ Lower resource usage
- ✅ Familiar UX for target users
- ❌ Cannot have natural conversation flow
- ❌ Future work needed for full-duplex

### Decision 3: No E2E Encryption for MVP

**Decision**: No end-to-end encryption in MVP  
**Date**: 2026-02-07  
**Rationale**:
- Adds significant complexity
- Increases latency
- Key management challenges
- Can be added post-MVP without breaking changes

**Trade-offs**:
- ✅ Lower latency
- ✅ Simpler implementation
- ✅ Faster MVP delivery
- ❌ Audio not encrypted end-to-end
- ❌ Trust server not to eavesdrop
- ⚠️ Must document security model clearly

**Security Mitigation**:
- Use TLS for control connections
- Optional DTLS for UDP packets
- Clearly document that audio is not E2E encrypted
- Plan E2E encryption for Phase 2

### Decision 4: Desktop First, Mobile Later

**Decision**: Desktop applications only for MVP  
**Date**: 2026-02-07  
**Rationale**:
- Target user base primarily on desktop
- Mobile UX requirements different
- Resource constraints
- Can validate concept on desktop first

**Trade-offs**:
- ✅ Faster MVP delivery
- ✅ Focus resources on core features
- ✅ Better initial UX on primary platform
- ❌ Cannot reach mobile users
- ❌ Future work needed for mobile

---

## Communication Guidelines

### For Stakeholders

When discussing features, use this terminology:

- **"In MVP"** or **"P0"**: Committed for MVP release
- **"Post-MVP"** or **"P1/P2"**: Planned for future releases
- **"Out of Scope"**: Not planned, won't be built

### For Users

When explaining limitations:

✅ **Do Say**:
- "KRT-Comms uses its own voice infrastructure, not Discord voice"
- "MVP focuses on push-to-talk; full-duplex planned for later"
- "Audio quality and latency are prioritized over encryption in MVP"
- "Desktop apps available now; mobile apps coming in future release"

❌ **Don't Say**:
- "We don't support that" (without explaining future plans)
- "That's too hard to build" (focus on priorities, not difficulty)
- "Maybe someday" (be clear about post-MVP plans vs. out-of-scope)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-07 | Initial document created |

---

## Approval

This document should be reviewed and approved by:

- [ ] Product Owner
- [ ] Technical Lead
- [ ] Architecture Team
- [ ] Stakeholders

**Approved By**: _________________  
**Date**: _________________

---

**Next Review**: 2026-03-07  
**Document Owner**: Product Team
