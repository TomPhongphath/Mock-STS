#!/bin/bash
# Script for Certbot to request Let's Encrypt certificates
# รันหลังจาก nginx ทำงานและ DNS ชี้โดเมนมาที่ server แล้ว
#
# วิธีใช้:
#   docker compose run certbot
#
# หรือกำหนด domain:
#   docker compose run certbot sh -c "certbot certonly --webroot -w /var/www/certbot -d yourdomain.com"

certbot certonly --webroot -w /var/www/certbot --email admin@yourdomain.com --agree-tos --non-interactive
