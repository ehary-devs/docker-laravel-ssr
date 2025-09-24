const path = require("path");
const LOG_DIR = process.env.PM2_LOG_DIR || "/app/pm2-logs";
const APP_CWD = process.env.APP_CWD || "/app";

const apps = [];

// SSR
apps.push({
  name: "ssr-app",
  script: process.env.SSR_ENTRY || "bootstrap/ssr/ssr.js",
  cwd: APP_CWD,
  interpreter: "node",
  exec_mode: "cluster",
  instances: process.env.SSR_INSTANCES || "max",
  autorestart: true,
  max_memory_restart: process.env.SSR_MEMORY || "512M",
  out_file: path.join(LOG_DIR, "ssr-app-out.log"),
  error_file: path.join(LOG_DIR, "ssr-app-error.log"),
});

// Scheduler
if (process.env.ENABLE_SCHEDULER === "true") {
  apps.push({
    name: "laravel-scheduler",
    script: "artisan",
    args: process.env.SCHEDULER_ARGS || "schedule:work",
    cwd: APP_CWD,
    interpreter: "php",
    exec_mode: "fork",
    autorestart: true,
    max_memory_restart: process.env.SCHEDULER_MEMORY || "512M",
    out_file: path.join(LOG_DIR, "laravel-scheduler-out.log"),
    error_file: path.join(LOG_DIR, "laravel-scheduler-error.log"),
  });
}

// Queue multiple
if (process.env.ENABLE_QUEUE === "true") {
  const queues = (process.env.QUEUE_LIST || "default").split(",");
  queues.forEach((q) => {
    const name = q.trim();
    if (!name) return;
    apps.push({
      name: `queue-${name}`,
      script: "artisan",
      args: `queue:work --queue=${name} --tries=${process.env.QUEUE_TRIES || 3} --timeout=${process.env.QUEUE_TIMEOUT || 60}`,
      cwd: APP_CWD,
      interpreter: "php",
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: process.env.QUEUE_MEMORY || "512M",
      out_file: path.join(LOG_DIR, `queue-${name}-out.log`),
      error_file: path.join(LOG_DIR, `queue-${name}-error.log`),
    });
  });
}

module.exports = { apps };
