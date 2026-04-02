module.exports = {
  apps: [{
    name: 'bmi-backend',
    script: './src/server.js',
    cwd: '/home/ubuntu/bmi-health-tracker/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/proc/1/fd/2',
    out_file: '/proc/1/fd/1',
    log_file: '/dev/null',
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
