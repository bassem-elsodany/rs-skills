# Domain Skills Test Scenarios

> Layer 3: Domain Constraints

## rs-domain-fintech

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `decimal precision for money` | rs-domain-fintech | rust_decimal, precision |
| `trading system design` | rs-domain-fintech | immutable audit, Arc |
| `how to design a trading system` | rs-domain-fintech | audit, immutable |
| `currency conversion in Rust` | rs-domain-fintech | decimal, exchange rate |

### Test Commands

```bash
claude -p "decimal precision for money"
claude -p "trading system design"
```

---

## rs-domain-web

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `axum web server` | rs-domain-web | handler, router, State |
| `how to write HTTP middleware` | rs-domain-web | middleware, tower |
| `REST API design in Rust` | rs-domain-web | extractor, response |
| `actix-web vs axum` | rs-domain-web + negotiation | comparison |

### Test Commands

```bash
claude -p "axum web server"
claude -p "how to write HTTP middleware"
```

---

## rs-domain-cli

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `clap CLI argument` | rs-domain-cli | derive, subcommand |
| `building a CLI tool` | rs-domain-cli | clap, args |
| `interactive terminal` | rs-domain-cli | ratatui, crossterm |

### Test Commands

```bash
claude -p "clap CLI argument"
claude -p "building a CLI tool"
```

---

## rs-domain-embedded

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `no_std embedded` | rs-domain-embedded | #![no_std], heapless |
| `embedded Rust development` | rs-domain-embedded | cortex-m, HAL |
| `STM32 in Rust` | rs-domain-embedded | stm32, PAC |
| `embedded-hal usage` | rs-domain-embedded | trait, peripheral |

### Test Commands

```bash
claude -p "no_std embedded"
claude -p "embedded Rust development"
```

---

## rs-domain-cloud-native

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `kubernetes operator in Rust` | rs-domain-cloud-native | kube-rs, CRD |
| `gRPC service` | rs-domain-cloud-native | tonic, protobuf |
| `microservice architecture in Rust` | rs-domain-cloud-native | observability, health check |

### Test Commands

```bash
claude -p "kubernetes operator in Rust"
claude -p "gRPC service"
```

---

## rs-domain-iot

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `IoT sensor` | rs-domain-iot | MQTT, telemetry |
| `IoT device communication in Rust` | rs-domain-iot | protocol, edge |
| `MQTT client in Rust` | rs-domain-iot | rumqttc, publish |

### Test Commands

```bash
claude -p "IoT sensor"
claude -p "MQTT client in Rust"
```

---

## rs-domain-ml

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `machine learning tensor in Rust` | rs-domain-ml | ndarray, candle |
| `ML inference in Rust` | rs-domain-ml | ONNX, model |
| `neural network` | rs-domain-ml | burn, training |

### Test Commands

```bash
claude -p "machine learning tensor in Rust"
claude -p "ML inference in Rust"
```

---

## Validation Checklist

- [ ] Each domain skill triggers correctly
- [ ] Domain-specific terminology recognized
- [ ] Chinese keywords trigger same skills
- [ ] Cross-domain queries load multiple skills
