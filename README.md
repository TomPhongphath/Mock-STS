# Mock STS Environment (Headscale, Databases & Auth Server)

โปรเจกต์จำลองสภาพแวดล้อมระบบเครือข่ายความปลอดภัย (Mesh VPN) และฐานข้อมูลสำหรับระบบ STS (แบ่งสภาพแวดล้อมเป็น UAT และ MASTER) เพื่อใช้ในขั้นตอนการทำ Mock-up และทดสอบระบบ (PoC) ร่วมกันในทีม

## 🏗️ โครงสร้างบริการภายในโปรเจกต์
- **Headscale Server (VPN Control Plane):** พอร์ต `8080`
- **PostgreSQL UAT Container:** พอร์ตภายนอก `5431` (ฐานข้อมูลในตู้ชื่อ `STS`)
- **PostgreSQL MASTER Container:** พอร์ตภายนอก `5432` (ฐานข้อมูลในตู้ชื่อ `STS`)
- **pgAdmin 4 (Database Web Management):** พอร์ต `5050` (ผูก Auto-connect เข้าฐานข้อมูลให้แล้ว)
- **Keycloak Server (Centralized Auth Provider):** พอร์ต `8081`

## 🚀 วิธีการเริ่มต้นใช้งาน (Quick Start)

1. ทำการ Clone โปรเจกต์ลงบนคอมพิวเตอร์ของคุณหรือบน VPS
2. เปิด Terminal ในตำแหน่ง Root ของโฟลเดอร์โปรเจกต์
3. สั่งรันชุดคอนเทนเนอร์ทั้งหมดด้วยคำสั่งเดียว:
   ```bash
   docker compose up -d
   ```
4. ระบบ `headscale-init` จะทำการดาวน์โหลดและสร้างไฟล์คอนฟิกเริ่มต้นให้คุณภายในโฟลเดอร์ `./headscale/config/config.yaml` โดยอัตโนมัติ

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
