const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 80;
const BFF_TYPE = process.env.BFF_TYPE || 'web';

const routeMap = {
  '/api_adm_service':       process.env.UPSTREAM_ADM,
  '/api_dashboard_service': process.env.UPSTREAM_DASHBOARD,
  '/api_master_service':    process.env.UPSTREAM_MASTER,
  '/api_teleport_service':  process.env.UPSTREAM_TELEPORT,
  '/api_install_service':   process.env.UPSTREAM_INSTALL,
  '/api_noc_service':       process.env.UPSTREAM_NOC,
  '/api_alert_service':     process.env.UPSTREAM_ALERT,
  '/api_ic_service':        process.env.UPSTREAM_IC,
};

const activeRoutes = Object.entries(routeMap).filter(([, target]) => target);

activeRoutes.forEach(([path, target]) => {
  console.log(`[bff-${BFF_TYPE}] Route ${path} -> ${target}`);
  app.use(path, createProxyMiddleware({
    target,
    changeOrigin: true,
    pathRewrite: { [`^${path}`]: '/' },
    on: {
      proxyReq: (proxyReq, req) => {
        proxyReq.setHeader('X-BFF-Type', BFF_TYPE);
        proxyReq.setHeader('X-Forwarded-For', req.ip);
      },
    },
  }));
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', bff_type: BFF_TYPE, routes: activeRoutes.length });
});

app.listen(PORT, () => {
  console.log(`[bff-${BFF_TYPE}] Listening on port ${PORT}`);
});
