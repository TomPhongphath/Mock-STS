# คู่มือการติดตั้งและใช้งาน Mock STS Environment

## สารบัญ
1. [ความต้องการของระบบ](#1-ความต้องการของระบบ)
2. [การติดตั้ง](#2-การติดตั้ง)
3. [การใช้งานครั้งแรก](#3-การใช้งานครั้งแรก)
4. [การจัดการ Headscale](#4-การจัดการ-headscale)
5. [การเชื่อมต่อฐานข้อมูล](#5-การเชื่อมต่อฐานข้อมูล)
6. [การใช้งาน pgAdmin](#6-การใช้งาน-pgadmin)
7. [การใช้งาน Keycloak](#7-การใช้งาน-keycloak)
8. [คำสั่ง Docker ที่ใช้บ่อย](#8-คำสั่ง-docker-ที่ใช้บ่อย)
9. [การแก้ไขปัญหาเบื้องต้น](#9-การแก้ไขปัญหาเบื้องต้น)
10. [การหยุดและลบระบบ](#10-การหยุดและลบระบบ)
11. [Network Architecture](#11-network-architecture)

---

## 1. ความต้องการของระบบ

### Software ที่ต้องติดตั้งล่วงหน้า
- **Docker Engine** (เวอร์ชัน 20.10 ขึ้นไป) หรือ **Docker Desktop**
- **Docker Compose** (เวอร์ชัน 2.x ขึ้นไป — ปกติมาพร้อม Docker Desktop)
- **Git** (สำหรับ Clone โปรเจกต์)

### ตรวจสอบเวอร์ชัน
```bash
docker --version
docker compose version
git --version
```

### พอร์ตที่ต้องว่าง
| พอร์ต | บริการ | ย้ายได้? |
|-------|--------|----------|
| 5431 | PostgreSQL UAT (ภายนอก) | ใช่ — เปลี่ยนใน `.env` |
| 5432 | PostgreSQL MASTER (ภายนอก) | ใช่ — เปลี่ยนใน `.env` |
| 5050 | pgAdmin Web UI | ใช่ — เปลี่ยนใน `.env` |
| 8080 | Headscale Server | ใช่ — เปลี่ยนใน `.env` |
| 8081 | Keycloak Server | ใช่ — เปลี่ยนใน `.env` |

> ทุกพอร์ตสามารถเปลี่ยนได้ผ่านตัวแปรในไฟล์ `.env`

---

## 2. การติดตั้ง

### 2.1 Clone โปรเจกต์
```bash
git clone https://github.com/TomPhongphath/Mock-STS.git
cd Mock-STS
```

### 2.2 สร้างไฟล์ `.env`
```powershell
Copy-Item -Path .env.example -Destination .env
```

หรือสร้างด้วยตนเอง:
```powershell
@"
POSTGRES_DB=STS
POSTGRES_USER=userSTS
POSTGRES_PASSWORD=S@mart@2024
PG_UAT_PORT=5431
PG_MASTER_PORT=5432
HS_PORT=8080
PGADMIN_PORT=5050
PGADMIN_EMAIL=admin@yourdomain.com
PGADMIN_PASSWORD=PgAdminSecurePass123!
KEYCLOAK_PORT=8081
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=KeycloakSecurePass123!
GITHUB_TOKEN=ghp_your_token_here
"@ | Set-Content -Path .env
```

### 2.3 ตรวจสอบโครงสร้างโฟลเดอร์
```bash
tree /F
```
ผลลัพธ์ที่ควรได้:
```
Mock-STS/
│
├── .env                     # ตัวแปรสภาพแวดล้อม (ถูก .gitignore)
├── .env.example             # Template สำหรับคน clone
├── .gitignore
├── .md
├── docker-compose.yml
├── DOCUMENTATION.md
├── README.md
│
├── headscale/
│   ├── config/
│   │   ├── .gitkeep
│   │   └── config.headscale.yaml   # Pre-configured template (คัดลอกไปเป็น config.yaml อัตโนมัติ)
│   └── data/
│
└── pgadmin/
    ├── servers.json
    └── pgpass               # (ถูก .gitignore)
```

### 2.4 ตั้งค่าไฟล์ pgpass
ไฟล์ `pgadmin/pgpass` ควรมีเนื้อหา:
```
postgres_uat:5432:STS:userSTS:S@mart@2024
postgres_master:5432:STS:userSTS:S@mart@2024
```

```powershell
@"
postgres_uat:5432:STS:userSTS:S@mart@2024
postgres_master:5432:STS:userSTS:S@mart@2024
"@ | Set-Content -Path pgadmin\pgpass
```

> **สำคัญ:** ไฟล์ `pgpass` ใน container ต้องมี permission `0600` มิฉะนั้น pgAdmin จะไม่โหลดไฟล์นี้
> ถ้าเจอปัญหาให้ตั้งค่าใน container:
> ```bash
> docker exec pgadmin_web chmod 0600 /tmp/pgpass
> docker restart pgadmin_web
> ```

---

## 3. การใช้งานครั้งแรก

### 3.1 รันทุกคอนเทนเนอร์
```bash
docker compose up -d
```

### 3.2 ตรวจสอบสถานะ
```bash
docker compose ps
```
ควรมองเห็นคอนเทนเนอร์ทั้งหมด 6 ตัว:
- `headscale_init` (จะรันแล้วหยุดไป — status: `Exited (0)`)
- `headscale`
- `postgres_uat`
- `postgres_master`
- `pgadmin_web`
- `keycloak_auth`

### 3.3 ดู logs แบบ实时
```bash
docker compose logs -f
```

หรือดู logs เฉพาะ service:
```bash
docker compose logs -f headscale
docker compose logs -f postgres_uat
docker compose logs -f pgadmin_web
```

### 3.4 ตรวจสอบว่า `config.yaml` ถูกสร้างแล้ว
```bash
dir headscale\config\
```

---

## 4. การจัดการ Headscale

### 4.1 สร้าง User (Namespace)
```bash
docker exec -it headscale headscale users create sts-users
```

### 4.2 สร้าง Pre-Auth Key สำหรับเชื่อมต่อ Node
```bash
docker exec -it headscale headscale preauthkeys create -u sts-users -e 24h
```
- `-e 24h` = คีย์หมดอายุใน 24 ชั่วโมง
- `-e 72h` = 72 ชั่วโมง
- `-e 0` = ไม่หมดอายุ

### 4.3 ตรวจสอบ Nodes ที่เชื่อมต่อแล้ว
```bash
docker exec -it headscale headscale nodes list
```

### 4.4 ดู Routes
```bash
docker exec -it headscale headscale routes list
```

---

## 5. การเชื่อมต่อฐานข้อมูล

### 5.1 PostgreSQL UAT
| รายการ | ค่า | เปลี่ยนได้ใน `.env` |
|--------|-----|---------------------|
| Host | `localhost` | |
| Port | `5431` | `PG_UAT_PORT` |
| Database | `STS` | `POSTGRES_DB` |
| Username | `userSTS` | `POSTGRES_USER` |
| Password | `S@mart@2024` | `POSTGRES_PASSWORD` |

### 5.2 PostgreSQL MASTER
| รายการ | ค่า | เปลี่ยนได้ใน `.env` |
|--------|-----|---------------------|
| Host | `localhost` | |
| Port | `5432` | `PG_MASTER_PORT` |
| Database | `STS` | `POSTGRES_DB` |
| Username | `userSTS` | `POSTGRES_USER` |
| Password | `S@mart@2024` | `POSTGRES_PASSWORD` |

### 5.3 ทดสอบเชื่อมต่อด้วย psql (จากเครื่อง Host)
```bash
# เชื่อมต่อ UAT
psql -h localhost -p 5431 -U userSTS -d STS

# เชื่อมต่อ MASTER
psql -h localhost -p 5432 -U userSTS -d STS
```
(จะถูกถามรหัสผ่าน: `S@mart@2024`)

### 5.4 ทดสอบเชื่อมต่อจากภายใน Docker
```bash
docker exec -it postgres_uat psql -U userSTS -d STS
docker exec -it postgres_uat psql -U userSTS -d STS -c "SELECT version();"
```

---

## 6. การใช้งาน pgAdmin

### 6.1 เข้าสู่ระบบ
1. เปิดเบราว์เซอร์ไปที่ [http://localhost:5050](http://localhost:5050)
2. อีเมล: `admin@yourdomain.com`
3. รหัสผ่าน: `PgAdminSecurePass123!`

### 6.2 การเชื่อมต่อฐานข้อมูล
pgAdmin ถูกตั้งค่า Auto-connect ไว้แล้วผ่าน `servers.json` และ `pgpass`:
- **STS - UAT Environment** → เชื่อมต่อไปยัง `postgres_uat:5432`
- **STS - MASTER Environment** → เชื่อมต่อไปยัง `postgres_master:5432`

ถ้าไม่เห็นเซิร์ฟเวอร์ ให้รีเฟรชหน้า หรือตรวจสอบ logs:
```bash
docker compose logs pgadmin_web
```

### 6.3 การเพิ่มเซิร์ฟเวอร์ด้วยตนเอง (ถ้าต้องการ)
1. คลิกขวาที่ `Servers` > `Register` > `Server`
2. **General tab:** ตั้งชื่อ เช่น `STS - UAT Manual`
3. **Connection tab:**
   - Host: `postgres_uat`
   - Port: `5432`
   - Maintenance database: `STS`
   - Username: `userSTS`
   - Password: `S@mart@2024`
4. คลิก Save

---

## 7. การใช้งาน Keycloak

### 7.1 เข้าสู่ระบบ Admin Console
1. เปิดเบราว์เซอร์ไปที่ [http://localhost:8081](http://localhost:8081)
2. คลิก `Administration Console`
3. Username: `admin`
4. Password: `KeycloakSecurePass123!`

### 7.2 สร้าง Realm (tenant)
1. ไปที่เมนูด้านซ้าย > คลิกที่ dropdown `master` > `Create Realm`
2. ใส่ Realm name: `sts-realm`
3. คลิก Create

### 7.3 สร้าง User ทดสอบ
1. เลือก Realm `sts-realm`
2. ไปที่ `Users` > `Add user`
3. ใส่ Username: `testuser`
4. คลิก Create
5. ไปที่ Tab `Credentials` > ตั้งรหัสผ่าน > ยกเลิก `Temporary`

### 7.4 สร้าง Client (สำหรับเชื่อมต่อจากแอปพลิเคชัน)
1. ไปที่ `Clients` > `Create client`
2. Client ID: `sts-client`
3. Client Protocol: `openid-connect`
4. คลิก Next > ตั้งค่า `Valid Redirect URIs` ตามต้องการ

### 7.5 ข้อมูลสำคัญเกี่ยวกับ Keycloak
- **โหมดการทำงาน:** `start --optimized` (production-ready)
- **Database backend:** ใช้ PostgreSQL MASTER (`postgres_master`) แทน H2 in-memory
- ข้อมูล Realm, User, Client ทั้งหมดถูกบันทึกลง PostgreSQL อย่างถาวร

---

## 8. คำสั่ง Docker ที่ใช้บ่อย

| คำสั่ง | คำอธิบาย |
|--------|----------|
| `docker compose up -d` | รันทุก service แบบ background |
| `docker compose down` | หยุดและลบทุก container, network |
| `docker compose down -v` | หยุดและลบทุกอย่างรวม volumes |
| `docker compose ps` | ดูสถานะ container |
| `docker compose logs -f` | ดู logs แบบ real-time |
| `docker compose logs -f <service>` | ดู logs เฉพาะ service |
| `docker compose restart <service>` | รีสตาร์ท service |
| `docker compose exec <service> <cmd>` | รันคำสั่งใน container |

---

## 9. การแก้ไขปัญหาเบื้องต้น

### 9.1 พอร์ตถูกใช้งานแล้ว
```bash
# ตรวจสอบพอร์ตที่ถูกใช้
netstat -ano | findstr :5431
netstat -ano | findstr :5432

# ถ้าพบ ให้เปลี่ยนพอร์ตใน .env แล้วรันใหม่
```

### 9.2 headscale_init ไม่ทำงาน
```bash
# ดู logs
docker compose logs headscale-init

# รัน init ใหม่
docker compose up -d headscale-init
docker compose logs headscale-init
```

### 9.3 PostgreSQL ไม่พร้อม
```bash
docker compose ps postgres_uat
docker compose logs postgres_uat
```

### 9.4 pgAdmin ไม่เห็นเซิร์ฟเวอร์
```bash
# ตรวจสอบว่า servers.json ถูก mount ถูกต้อง
docker exec pgadmin_web cat /pgadmin4/servers.json

# ตรวจสอบ pgpass
docker exec pgadmin_web cat /tmp/pgpass
```

### 9.5 Keycloak เริ่มต้นไม่สำเร็จ
```bash
docker compose logs keycloak_auth
```
Keycloak อาจใช้เวลาเริ่มต้นนาน (30-60 วินาที) ครั้งแรก โดยเฉพาะเมื่อสร้าง database schema ใน PostgreSQL

### 9.6 Headscale ไม่เชื่อมต่อ PostgreSQL (config mismatch)
```bash
# ตรวจสอบว่า config.yaml มี PostgreSQL config ถูกต้อง
docker exec headscale cat /etc/headscale/config.yaml | Select-String -Pattern "database|postgres|host|port"

# ถ้าไม่ถูกต้อง — ลบแล้วให้ headscale-init สร้างใหม่
Remove-Item -LiteralPath headscale\config\config.yaml -Force
docker compose up -d headscale-init
docker compose restart headscale
```

---

## 10. การหยุดและลบระบบ

### 10.1 หยุดการทำงานชั่วคราว
```bash
docker compose stop
```

### 10.2 เริ่มต้นใหม่ (ข้อมูลยังอยู่)
```bash
docker compose start
```

### 10.3 หยุดและลบ containers (ข้อมูลยังอยู่)
```bash
docker compose down
```

### 10.4 ลบทุกอย่างรวมฐานข้อมูล
```bash
docker compose down -v
```

> **คำเตือน:** `-v` จะลบ volumes ทั้งหมดรวมข้อมูล PostgreSQL ด้วย

### 10.5 รีเซ็ต Headscale config
```bash
# ลบ config.yaml เพื่อให้ headscale-init สร้างใหม่
docker compose exec headscale rm /etc/headscale/config.yaml

# หรือจากเครื่อง host
Remove-Item -LiteralPath headscale\config\config.yaml -Force

# รัน init ใหม่
docker compose up -d headscale-init

# รีสตาร์ท headscale
docker compose restart headscale
```

---

## 11. Network Architecture

ระบบใช้ Docker networks แบบแยกส่วน เพื่อความปลอดภัย:

```
                    ┌─────────────────────┐
                    │   sts-frontend      │
                    │  (เข้าถึงจากนอก)    │
                    │                     │
                    │  ┌──────────────┐   │
                    │  │  headscale   │   │
                    │  │  :8080       │   │
                    │  └──────┬───────┘   │
                    │         │           │
                    │  ┌──────┴───────┐   │
                    │  │  pgadmin_web │   │
                    │  │  :5050       │   │
                    │  └──────┬───────┘   │
                    │         │           │
                    │  ┌──────┴───────┐   │
                    │  │ keycloak_auth│   │
                    │  │  :8081       │   │
                    │  └─────────────┘   │
                    └────────┬───────────┘
                             │
    ─────────────────────────┼─────────────────────
                             │
                    ┌────────┴───────────┐
                    │   sts-backend      │
                    │  (ภายในเท่านั้น)   │
                    │                     │
                    │  ┌──────────────┐   │
                    │  │ postgres_uat │   │
                    │  │  :5432       │   │
                    │  └──────────────┘   │
                    │                     │
                    │  ┌────────────────┐ │
                    │  │ postgres_master│ │
                    │  │  :5432         │ │
                    │  └────────────────┘ │
                    └─────────────────────┘
```

**หลักการ:**
- `sts-backend`: PostgreSQL containers (ไม่ควร expose โดยตรง)
- `sts-frontend` + `sts-backend`: Headscale, pgAdmin, Keycloak (service ที่ต้องคุยกับ DB จะอยู่ใน 2 networks)
- พอร์ตภายนอก (`5431`, `5432`) ยังคงเปิดไว้สำหรับ tools ภายนอก (เช่น psql, DBeaver)

---

## ข้อมูลเพิ่มเติม

- **Git Repository:** [https://github.com/TomPhongphath/Mock-STS](https://github.com/TomPhongphath/Mock-STS)
- **Headscale Documentation:** [https://headscale.net/](https://headscale.net/)
- **pgAdmin Documentation:** [https://www.pgadmin.org/docs/](https://www.pgadmin.org/docs/)
- **Keycloak Documentation:** [https://www.keycloak.org/documentation](https://www.keycloak.org/documentation)
