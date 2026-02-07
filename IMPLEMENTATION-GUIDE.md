# KRT-Comms for Discord - Implementation Guide

**Version:** 1.0  
**Last Updated:** 2026-02-07  
**Audience:** Developers implementing KRT-Comms

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Project Structure](#project-structure)
3. [Development Setup](#development-setup)
4. [Building Components](#building-components)
5. [Testing Strategy](#testing-strategy)
6. [Deployment](#deployment)
7. [Contributing Guidelines](#contributing-guidelines)

---

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for Control Service and Discord Bot)
- Rust 1.70+ (for Voice Service) OR Go 1.21+
- Python 3.10+ (for tooling/scripts)
- Git

### Initial Setup

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/krt-comms.git
cd krt-comms

# 2. Copy environment template
cp .env.example .env

# 3. Edit .env with your configuration
nano .env

# 4. Start infrastructure services (PostgreSQL, Redis)
docker-compose up -d postgresql valkey

# 5. Run database migrations
npm run db:migrate

# 6. Start development services
npm run dev:all
```

### Verify Installation

```bash
# Check services are running
curl http://localhost:3000/health        # Control Service
curl http://localhost:3001/health        # Discord Bot (if running)

# Check database
docker exec -it krt-comms-postgres psql -U krtuser -d krtcomms -c "\dt"

# Check Redis
docker exec -it krt-comms-redis redis-cli PING
```

---

## Project Structure

```
krt-comms/
├── docs/                           # Documentation
│   ├── KRT-COMMS-SPECIFICATION.md # Full specification
│   ├── ARCHITECTURE.md            # System architecture
│   └── IMPLEMENTATION-GAP-ANALYSIS.md
├── services/                       # Backend services
│   ├── control-service/           # REST API & WebSocket
│   │   ├── src/
│   │   │   ├── api/              # API routes
│   │   │   ├── models/           # Database models
│   │   │   ├── services/         # Business logic
│   │   │   ├── middleware/       # Express middleware
│   │   │   └── utils/            # Utilities
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── voice-service/             # UDP audio service
│   │   ├── src/
│   │   │   ├── main.rs          # Entry point
│   │   │   ├── audio/           # Opus codec
│   │   │   ├── network/         # UDP handling
│   │   │   └── routing/         # Packet routing
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── Cargo.toml
│   └── discord-service/           # Discord bot
│       ├── src/
│       │   ├── commands/         # Slash commands
│       │   ├── handlers/         # Event handlers
│       │   └── api-client.js    # Control Service client
│       ├── Dockerfile
│       └── package.json
├── client/                         # Desktop application
│   ├── src/
│   │   ├── main/                 # Electron main process
│   │   │   ├── index.ts
│   │   │   ├── audio/           # Audio engine
│   │   │   ├── network/         # Network layer
│   │   │   └── hotkeys/         # Hotkey management
│   │   └── renderer/            # React UI
│   │       ├── App.tsx
│   │       ├── components/
│   │       ├── hooks/
│   │       └── services/
│   ├── package.json
│   └── webpack.config.js
├── database/                       # Database schemas
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_frequencies.sql
│   │   └── 003_hotkeys.sql
│   └── seeds/
│       └── default_frequencies.sql
├── shared/                         # Shared code
│   ├── types/                    # TypeScript types
│   └── constants/                # Shared constants
├── docker-compose.yml             # Development compose
├── docker-compose.prod.yml        # Production compose
├── .env.example                   # Environment template
└── README.md
```

---

## Development Setup

### Environment Variables

Create `.env` file:

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=krtcomms
DB_USER=krtuser
DB_PASSWORD=your_secure_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# Control Service
CONTROL_SERVICE_PORT=3000
JWT_SECRET=your_jwt_secret_key_min_32_chars
JWT_EXPIRES_IN=24h

# Voice Service
VOICE_SERVICE_UDP_PORT_START=50000
VOICE_SERVICE_UDP_PORT_END=50010

# Discord Bot
DISCORD_TOKEN=your_discord_bot_token
DISCORD_APP_ID=your_discord_app_id
DISCORD_GUILD_ID=your_test_guild_id

# Environment
NODE_ENV=development
LOG_LEVEL=debug
```

### Database Setup

```bash
# Start PostgreSQL
docker-compose up -d postgresql

# Create database
docker exec -it krt-comms-postgres psql -U postgres -c "CREATE DATABASE krtcomms;"
docker exec -it krt-comms-postgres psql -U postgres -c "CREATE USER krtuser WITH PASSWORD 'your_password';"
docker exec -it krt-comms-postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE krtcomms TO krtuser;"

# Run migrations
cd services/control-service
npm run db:migrate

# Seed data
npm run db:seed
```

### Redis Setup

```bash
# Start Redis
docker-compose up -d valkey

# Verify connection
docker exec -it krt-comms-redis redis-cli PING
# Should respond: PONG
```

---

## Building Components

### Control Service (Node.js + TypeScript)

```bash
cd services/control-service

# Install dependencies
npm install

# Run in development mode (with hot reload)
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Run linter
npm run lint

# Type check
npm run typecheck
```

**Project Setup**:

```bash
# Initialize project
mkdir -p services/control-service
cd services/control-service
npm init -y

# Install dependencies
npm install express socket.io jsonwebtoken bcrypt pg redis
npm install --save-dev typescript @types/node @types/express ts-node nodemon

# Create tsconfig.json
npx tsc --init
```

**Example API Route**:

```typescript
// services/control-service/src/api/frequencies.ts
import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import FrequencyService from '../services/frequency-service';

const router = Router();

router.get('/frequencies', authenticateToken, async (req, res) => {
    try {
        const frequencies = await FrequencyService.listAll();
        res.json(frequencies);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch frequencies' });
    }
});

router.post('/frequencies/tune', authenticateToken, async (req, res) => {
    const { frequency_id } = req.body;
    const user_id = req.user.id;
    
    try {
        await FrequencyService.tuneFrequency(user_id, frequency_id);
        res.json({ success: true });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

export default router;
```

---

### Voice Service (Rust)

```bash
cd services/voice-service

# Build
cargo build

# Build for production
cargo build --release

# Run
cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Lint
cargo clippy
```

**Project Setup**:

```bash
# Initialize project
cargo new voice-service
cd voice-service

# Add dependencies to Cargo.toml
```

**Cargo.toml**:

```toml
[package]
name = "voice-service"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.35", features = ["full"] }
opus = "0.3"
redis = { version = "0.23", features = ["tokio-comp", "connection-manager"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
log = "0.4"
env_logger = "0.11"
bytes = "1.5"
```

**Example UDP Server**:

```rust
// services/voice-service/src/network/udp_server.rs
use tokio::net::UdpSocket;
use std::sync::Arc;

pub struct UdpServer {
    socket: Arc<UdpSocket>,
}

impl UdpServer {
    pub async fn new(addr: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let socket = UdpSocket::bind(addr).await?;
        log::info!("UDP server listening on {}", addr);
        
        Ok(Self {
            socket: Arc::new(socket),
        })
    }
    
    pub async fn run(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut buf = vec![0u8; 1500]; // MTU size
        
        loop {
            let (len, addr) = self.socket.recv_from(&mut buf).await?;
            let packet = &buf[..len];
            
            // Process packet
            if let Err(e) = self.process_packet(packet, addr).await {
                log::error!("Error processing packet: {}", e);
            }
        }
    }
    
    async fn process_packet(&self, packet: &[u8], addr: std::net::SocketAddr) 
        -> Result<(), Box<dyn std::error::Error>> 
    {
        // Parse and route packet
        // Implementation details...
        Ok(())
    }
}
```

---

### Client Application (Electron + React)

```bash
cd client

# Install dependencies
npm install

# Run in development mode
npm start

# Build for production
npm run build

# Package for distribution
npm run package:linux    # or :windows or :mac

# Run tests
npm test
```

**Project Setup**:

```bash
mkdir -p client
cd client
npm init -y

# Install Electron and React
npm install electron react react-dom
npm install --save-dev @electron-forge/cli webpack typescript @types/react

# Initialize Electron Forge
npx electron-forge import
```

**Example Main Process**:

```typescript
// client/src/main/index.ts
import { app, BrowserWindow, ipcMain } from 'electron';
import { AudioEngine } from './audio/audio-engine';
import { NetworkManager } from './network/network-manager';
import { HotkeyManager } from './hotkeys/hotkey-manager';

let mainWindow: BrowserWindow | null = null;
let audioEngine: AudioEngine | null = null;
let networkManager: NetworkManager | null = null;
let hotkeyManager: HotkeyManager | null = null;

async function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        }
    });
    
    mainWindow.loadURL('http://localhost:3000'); // Dev server
}

app.whenReady().then(async () => {
    // Initialize components
    audioEngine = new AudioEngine();
    networkManager = new NetworkManager();
    hotkeyManager = new HotkeyManager();
    
    // Set up IPC handlers
    ipcMain.handle('audio:start-capture', async () => {
        return audioEngine?.startCapture();
    });
    
    ipcMain.handle('frequency:tune', async (event, frequencyId) => {
        return networkManager?.tuneFrequency(frequencyId);
    });
    
    ipcMain.handle('hotkey:register', async (event, keyCombo, action) => {
        return hotkeyManager?.register(keyCombo, action);
    });
    
    await createWindow();
});
```

**Example React Component**:

```typescript
// client/src/renderer/components/FrequencyList.tsx
import React, { useState, useEffect } from 'react';

interface Frequency {
    id: number;
    display: string;
    description: string;
    isMonitoring: boolean;
}

export const FrequencyList: React.FC = () => {
    const [frequencies, setFrequencies] = useState<Frequency[]>([]);
    
    useEffect(() => {
        // Fetch frequencies from API
        window.api.getFrequencies().then(setFrequencies);
    }, []);
    
    const handleTune = async (frequencyId: number) => {
        await window.api.tuneFrequency(frequencyId);
        // Update state...
    };
    
    return (
        <div className="frequency-list">
            <h2>Active Frequencies</h2>
            {frequencies.map(freq => (
                <div key={freq.id} className="frequency-item">
                    <span>{freq.display}</span>
                    <span>{freq.description}</span>
                    <button onClick={() => handleTune(freq.id)}>
                        {freq.isMonitoring ? 'Leave' : 'Tune'}
                    </button>
                </div>
            ))}
        </div>
    );
};
```

---

### Discord Bot

```bash
cd services/discord-service

# Install dependencies
npm install

# Run in development
npm run dev

# Build for production
npm run build

# Deploy commands to Discord
npm run deploy-commands
```

**Example Command**:

```javascript
// services/discord-service/src/commands/freq-list.js
const { SlashCommandBuilder } = require('discord.js');
const ApiClient = require('../api-client');

module.exports = {
    data: new SlashCommandBuilder()
        .setName('krt-freq')
        .setDescription('Manage KRT-Comms frequencies')
        .addSubcommand(subcommand =>
            subcommand
                .setName('list')
                .setDescription('List all available frequencies')
        ),
    
    async execute(interaction) {
        await interaction.deferReply();
        
        try {
            const frequencies = await ApiClient.getFrequencies();
            
            const embed = {
                title: 'Available Frequencies',
                fields: frequencies.map(f => ({
                    name: f.frequency_display,
                    value: f.description || 'No description',
                    inline: true
                })),
                color: 0x0099ff
            };
            
            await interaction.editReply({ embeds: [embed] });
        } catch (error) {
            await interaction.editReply({ 
                content: 'Failed to fetch frequencies',
                ephemeral: true 
            });
        }
    }
};
```

---

## Testing Strategy

### Unit Tests

**Control Service**:
```bash
# Run all tests
npm test

# Run specific test file
npm test -- src/services/frequency-service.test.ts

# Watch mode
npm test -- --watch

# Coverage
npm test -- --coverage
```

**Voice Service**:
```bash
# Run all tests
cargo test

# Run specific test
cargo test test_packet_parsing

# Run with output
cargo test -- --nocapture
```

### Integration Tests

```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
npm run test:integration

# Cleanup
docker-compose -f docker-compose.test.yml down
```

### End-to-End Tests

```bash
# Using Playwright for client testing
cd client
npm run test:e2e
```

**Example E2E Test**:

```typescript
// client/tests/e2e/frequency-tuning.spec.ts
import { test, expect } from '@playwright/test';

test('user can tune to a frequency', async ({ page }) => {
    await page.goto('http://localhost:3000');
    
    // Login
    await page.fill('[data-testid="username"]', 'testuser');
    await page.fill('[data-testid="password"]', 'testpass');
    await page.click('[data-testid="login-button"]');
    
    // Tune to frequency
    await page.click('[data-testid="frequency-121500"]');
    await page.click('[data-testid="tune-button"]');
    
    // Verify frequency is active
    await expect(page.locator('[data-testid="active-frequency"]'))
        .toContainText('121.500');
});
```

---

## Deployment

### Docker Deployment

```bash
# Build all images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Kubernetes Deployment

```bash
# Apply configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/

# Check status
kubectl get pods -n krt-comms
kubectl get services -n krt-comms

# View logs
kubectl logs -f deployment/control-service -n krt-comms
```

### Production Checklist

- [ ] Update all secrets and passwords
- [ ] Enable TLS/HTTPS on Control Service
- [ ] Configure firewall rules for UDP ports
- [ ] Set up database backups
- [ ] Configure Redis persistence
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Configure logging (ELK or Loki)
- [ ] Set up alerting
- [ ] Performance test with expected load
- [ ] Security audit

---

## Contributing Guidelines

### Code Style

- **TypeScript/JavaScript**: Follow Airbnb style guide
- **Rust**: Use `rustfmt` defaults
- **Commits**: Conventional Commits format

```
feat: add frequency filtering
fix: resolve audio device enumeration bug
docs: update API documentation
test: add tests for hotkey manager
```

### Pull Request Process

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and commit
4. Write/update tests
5. Ensure all tests pass: `npm test` / `cargo test`
6. Push to your fork
7. Create Pull Request with description

### Code Review Checklist

- [ ] Code follows project style guide
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] No linting errors
- [ ] All tests pass
- [ ] No security vulnerabilities introduced

---

## Troubleshooting

### Common Issues

**Issue**: Cannot connect to PostgreSQL
```bash
# Solution: Check if PostgreSQL is running
docker ps | grep postgres

# Check logs
docker logs krt-comms-postgres

# Verify connection
docker exec -it krt-comms-postgres psql -U krtuser -d krtcomms
```

**Issue**: UDP packets not being received
```bash
# Solution: Check firewall rules
sudo ufw status
sudo ufw allow 50000:50010/udp

# Check if service is listening
sudo netstat -tulpn | grep 50000
```

**Issue**: Audio device enumeration fails
```bash
# Solution: On Linux, ensure user is in audio group
sudo usermod -a -G audio $USER

# Logout and login again
```

**Issue**: Discord bot not responding
```bash
# Solution: Verify bot token and permissions
# Check logs
docker logs krt-comms-discord-bot

# Verify bot has correct intents enabled in Discord Developer Portal
```

---

## Additional Resources

- [Opus Codec Documentation](https://opus-codec.org/docs/)
- [Discord.js Guide](https://discordjs.guide/)
- [Electron Documentation](https://www.electronjs.org/docs/latest)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

---

## License

[Specify your license here]

---

## Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Discord**: [Your Discord Server]
- **Email**: [Support Email]

---

**Last Updated**: 2026-02-07  
**Version**: 1.0.0
