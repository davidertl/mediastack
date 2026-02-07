# KRT-Comms for Discord - Documentation Index

**Version:** 1.0  
**Last Updated:** 2026-02-07

---

## 📋 Overview

This repository contains comprehensive documentation for **KRT-Comms for Discord**, a voice communication system designed for multi-frequency push-to-talk (PTT) communications with Discord integration.

> **Note**: This repository currently contains the MediaStack Docker configuration project. The KRT-Comms documentation represents a proposed specification for a new voice communication system that could potentially leverage the existing Docker infrastructure (PostgreSQL, Redis, etc.) from MediaStack.

---

## 📚 Documentation Structure

### Core Documentation

1. **[KRT-Comms Specification](./KRT-COMMS-SPECIFICATION.md)** ⭐ START HERE
   - Complete technical specification
   - System requirements and features
   - Audio transport architecture
   - Frequency management
   - Client-side mixing
   - GUI requirements
   - Database schemas
   - Discord bot integration
   
2. **[System Architecture](./ARCHITECTURE.md)**
   - Detailed component architecture
   - Service interaction diagrams
   - Network architecture
   - Deployment strategies
   - Monitoring and observability

3. **[Implementation Gap Analysis](./IMPLEMENTATION-GAP-ANALYSIS.md)**
   - Current state assessment
   - Gap identification by component
   - Implementation priorities
   - Resource requirements
   - Risk assessment

4. **[Implementation Guide](./IMPLEMENTATION-GUIDE.md)**
   - Developer setup instructions
   - Building components
   - Testing strategies
   - Deployment procedures
   - Troubleshooting guide

5. **[Non-Goals and MVP Scope](./NON-GOALS-AND-MVP-SCOPE.md)**
   - What IS included in MVP
   - What IS NOT included in MVP
   - Feature boundaries
   - Decision rationale

---

## 🎯 Quick Start Guide

### For Stakeholders and Product Managers

1. Read: [Non-Goals and MVP Scope](./NON-GOALS-AND-MVP-SCOPE.md)
   - Understand what's in and out of scope
   - Review MVP success criteria

2. Review: [KRT-Comms Specification](./KRT-COMMS-SPECIFICATION.md)
   - Core requirements
   - System capabilities
   - User experience

### For Architects and Technical Leads

1. Read: [System Architecture](./ARCHITECTURE.md)
   - Component design
   - Technology choices
   - Scalability approach

2. Review: [Implementation Gap Analysis](./IMPLEMENTATION-GAP-ANALYSIS.md)
   - Current state vs. target state
   - Implementation phases
   - Resource planning

### For Developers

1. Read: [Implementation Guide](./IMPLEMENTATION-GUIDE.md)
   - Development setup
   - Build procedures
   - Testing approach

2. Reference: [KRT-Comms Specification](./KRT-COMMS-SPECIFICATION.md)
   - Technical details
   - API specifications
   - Database schemas

---

## 🔑 Key Features

### ✅ Included in MVP

- **UDP Audio Transport** with Opus codec
- **Multi-Frequency Support** with integer-based frequency IDs
- **Client-Side Audio Mixing** of multiple streams
- **Push-to-Talk (PTT)** with configurable hotkeys
- **Hot-Swappable Audio Devices** without restart
- **Desktop GUI Application** (Windows, macOS, Linux)
- **Backend Services** (Control + Voice services)
- **PostgreSQL** for persistence
- **Redis** for real-time state
- **Discord Bot Integration** for frequency management

### ❌ Explicitly NOT in MVP

- ❌ Discord voice channel integration
- ❌ Full-duplex communication (PTT only)
- ❌ End-to-end encryption
- ❌ Native mobile applications
- ❌ Recording and playback features
- ❌ Video support

See [Non-Goals and MVP Scope](./NON-GOALS-AND-MVP-SCOPE.md) for complete details.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Client Desktop Application                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  GUI Layer   │  │ Audio Engine │  │ Input Handler│      │
│  │  (React)     │  │  (Opus)      │  │  (PTT/Keys)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
      ┌───────▼────────┐    ┌──────▼────────┐
      │ Control Service│    │ Voice Service │
      │   (REST/WS)    │    │   (UDP)       │
      └───────┬────────┘    └──────┬────────┘
              │                    │
      ┌───────▼────────────────────▼────────┐
      │  PostgreSQL    │     Redis          │
      │  (Persistent)  │     (Real-time)    │
      └────────────────┴────────────────────┘
                         │
                 ┌───────▼────────┐
                 │  Discord Bot   │
                 └────────────────┘
```

---

## 📊 Implementation Status

### Current State

| Component | Status | Notes |
|-----------|--------|-------|
| Specification | ✅ Complete | See KRT-COMMS-SPECIFICATION.md |
| Architecture | ✅ Complete | See ARCHITECTURE.md |
| Gap Analysis | ✅ Complete | See IMPLEMENTATION-GAP-ANALYSIS.md |
| Implementation Guide | ✅ Complete | See IMPLEMENTATION-GUIDE.md |
| Control Service | ❌ Not Started | Backend REST API |
| Voice Service | ❌ Not Started | UDP audio service |
| Client Application | ❌ Not Started | Desktop app |
| Discord Bot | ❌ Not Started | Bot integration |
| Database Schema | ❌ Not Started | PostgreSQL tables |

### Next Steps

1. **Review and approve** all specification documents
2. **Set up development environment** and project structure
3. **Begin Phase 1**: Backend services (Control Service + database)
4. **Begin Phase 2**: Voice Service with Opus codec
5. **Begin Phase 3**: Client desktop application

---

## 🤝 Contributing

This is currently a specification and planning repository. Once implementation begins, contribution guidelines will be established.

For now, feedback on the specifications is welcome:

1. Review the documentation
2. Open an issue for questions or suggestions
3. Propose changes via pull requests

---

## 📖 Additional Resources

### Technology References

- [Opus Codec](https://opus-codec.org/) - Audio codec documentation
- [WebRTC](https://webrtc.org/) - Real-time communication patterns
- [Discord API](https://discord.com/developers/docs) - Discord bot integration
- [PostgreSQL](https://www.postgresql.org/docs/) - Database documentation
- [Redis](https://redis.io/documentation) - Cache documentation

### Related Projects

- [MediaStack](./README.md) - Original Docker media server infrastructure

---

## 📞 Support

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: All docs in this repository

---

## 📄 License

[To be determined]

---

## 🗂️ Repository Context

This repository originally contained **MediaStack**, a Docker-based media server management system. The KRT-Comms documentation has been added to explore the potential for a voice communication system that could leverage MediaStack's existing infrastructure components (PostgreSQL, Redis/Valkey, Docker Compose setup).

### MediaStack Project

MediaStack provides Docker Compose configurations for:
- Media servers (Jellyfin, Plex)
- *ARR applications (Radarr, Sonarr, Lidarr, etc.)
- VPN tunneling (Gluetun)
- Reverse proxy (Traefik)
- Authentication (Authentik)
- Databases (PostgreSQL, Redis/Valkey)

See the [original MediaStack README](./README.md) for details.

### Infrastructure Reuse

KRT-Comms could potentially leverage:
- ✅ PostgreSQL container (for user/frequency data)
- ✅ Redis/Valkey container (for real-time state)
- ✅ Docker Compose infrastructure
- ✅ Traefik reverse proxy (for Control Service)

This would reduce setup complexity while keeping the two systems logically separate.

---

## 📅 Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | 2026-02-07 | Initial specification and documentation |

---

**Last Updated**: 2026-02-07  
**Status**: Specification Phase  
**Next Review**: 2026-02-14
