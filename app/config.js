// Global configuration for service URLs
// This will be populated from the environment or manually set
const CONFIG = {
    // Get EC2 IP from environment variable or use localhost for development
    EC2_IP: window.location.hostname || 'localhost',
    
    // Service ports
    SERVICES: {
        NGINX: 9080,
        APACHE: 9081,
        BUSYBOX: 9082,
        MEMCACHED: 9083,
        APP: 3000,
        ALPINE: 9084,
        REDIS: 9085,
        POSTGRES: 9086,
        MONGO: 9087,
        MYSQL: 9088,
        RABBITMQ: 9089,
        ELASTICSEARCH: 9091,
        GRAFANA: 3001,
        PROMETHEUS: 9093,
        JENKINS: 8001,
        GITLAB: 9092,
        DOCKER_REGISTRY: 5000,
        PORTAINER: 8002,
        VAULT: 8200,
        CONSUL: 8500,
        ETCD: 2379
    },
    
    // Get service URL
    getServiceUrl: function(serviceName) {
        const port = this.SERVICES[serviceName.toUpperCase()];
        if (!port) {
            console.error(`Service ${serviceName} not found`);
            return '';
        }
        return `http://${this.EC2_IP}:${port}`;
    },
    
    // Update all service links dynamically
    updateServiceLinks: function() {
        // Update Nginx link
        const nginxLink = document.querySelector('a[href*="9080"]');
        if (nginxLink) nginxLink.href = this.getServiceUrl('nginx');
        
        // Update Apache link
        const apacheLink = document.querySelector('a[href*="9081"]');
        if (apacheLink) apacheLink.href = this.getServiceUrl('apache');
        
        // Update BusyBox link
        const busyboxLink = document.querySelector('a[href*="9082"]');
        if (busyboxLink) busyboxLink.href = this.getServiceUrl('busybox');
        
        // Update Memcached link
        const memcachedLink = document.querySelector('a[href*="9083"]');
        if (memcachedLink) memcachedLink.href = this.getServiceUrl('memcached');
        
        // Update App link
        const appLink = document.querySelector('a[href*="3000"]');
        if (appLink) appLink.href = this.getServiceUrl('app');
        
        console.log(`Service links updated for IP: ${this.EC2_IP}`);
    }
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    CONFIG.updateServiceLinks();
});
