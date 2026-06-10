# Mock STS Environment (Headscale, Databases & Auth Server)

โปรเจกต์จำลองสภาพแวดล้อมระบบเครือข่ายความปลอดภัย (Mesh VPN) และฐานข้อมูลสำหรับระบบ STS (แบ่งสภาพแวดล้อมเป็น UAT และ MASTER) เพื่อใช้ในขั้นตอนการทำ Mock-up และทดสอบระบบ (PoC) ร่วมกันในทีม

## 🏗️ โครงสร้างบริการภายในโปรเจกต์
- **Headscale Server (VPN Control Plane):** พอร์ต `8080`
- **PostgreSQL UAT Container:** พอร์ตภายนอก `5431` (ฐานข้อมูลในตู้ชื่อ `STS`)
- **PostgreSQL MASTER Container:** พอร์ตภายนอก `5432` (ฐานข้อมูลในตู้ชื่อ `STS`)
- **pgAdmin 4 (Database Web Management):** พอร์ต `5050` (ผูก Auto-connect เข้าฐานข้อมูลให้แล้ว)
- **Keycloak Server (Centralized Auth Provider):** พอร์ต `8081` (ใช้ PostgreSQL MASTER เป็น backend)

## ✨ การปรับปรุงจากเวอร์ชันแรก
| หัวข้อ | การปรับปรุง |
|-------|-------------|
| Headscale config | ใช้ static template แทน `wget` + `sed` ป้องกัน structural changes |
| Keycloak | ใช้ `start --optimized` + PostgreSQL backend แทน `start-dev` + H2 |
| Secrets management | credentials ทั้งหมด移至 `.env`, รองรับ Docker variable substitution |
| Network isolation | แยก `sts-frontend` / `sts-backend` networks |
| Headscale-init | ใช้ `cp` จาก local template แทน `wget` ไม่ต้องพึ่ง network |

## 🚀 วิธีการเริ่มต้นใช้งาน (Quick Start)

1. Clone โปรเจกต์:
   ```bash
   git clone https://github.com/TomPhongphath/Mock-STS.git
   cd Mock-STS
   ```

2. สร้างไฟล์ `.env` (หรือ copy จาก `.env.example`):
   ```bash
   cp .env.example .env
   ```

3. สร้างไฟล์ `pgadmin/pgpass` สำหรับ auto-connect:
   ```bash
   echo "postgres_uat:5432:STS:userSTS:S@mart@2024" > pgadmin/pgpass
   echo "postgres_master:5432:STS:userSTS:S@mart@2024" >> pgadmin/pgpass
   ```

4. รันทุกคอนเทนเนอร์:
   ```bash
   docker compose up -d
   ```

5. `headscale-init` จะคัดลอกไฟล์คอนฟิกสำเร็จรูปไปเป็น `config.yaml` โดยอัตโนมัติ

## 💻 บัญชีผู้ใช้เริ่มต้นสำหรับทดสอบระบบ (Credentials)

* **pgAdmin Web UI (`http://localhost:5050`):**
  * Email: `admin@yourdomain.com`
  * Password: `PgAdminSecurePass123!`

* **Keycloak Admin Panel (`http://localhost:8081`):**
  * Username: `admin`
  * Password: `KeycloakSecurePass123!`

* **PostgreSQL Connection Details (ทั้ง UAT และ MASTER):**
  * User ID: `userSTS`
  * Password: `S@mart@2024`

> เปลี่ยน credentials ได้ในไฟล์ `.env`

ดูคู่มือฉบับเต็มได้ที่ [`DOCUMENTATION.md`](DOCUMENTATION.md)
