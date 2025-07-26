# Oracle APEX 24.1 Images Integration

## Overview

This document describes the Oracle APEX 24.1 images integration that has been added to the OCI Terraform with Ansible provisioning configuration. The integration provides automatic installation and configuration of APEX static images to be served through Tomcat.

## Implementation Details

### APEX Role Structure

The APEX integration is implemented as a dedicated Ansible role located at `ansible/roles/apex/`:

```
ansible/roles/apex/
├── defaults/main.yml           # Default variables
├── handlers/main.yml           # Service handlers
├── tasks/main.yml             # Main installation tasks
└── templates/
    ├── apex-images-context.xml.j2    # Tomcat context configuration
    ├── apex-info.txt.j2               # Installation information
    └── verify-apex-images.sh.j2       # Verification script
```

### Installation Process

1. **Download APEX 24.1**: Downloads the official Oracle APEX 24.1 archive from Oracle's repository
2. **Extract Archive**: Extracts the APEX installation files to a temporary directory
3. **Install Images**: Copies APEX images to Tomcat's webapps directory at `/opt/tomcat/webapps/i/`
4. **Configure Context**: Creates Tomcat context configuration for serving APEX images
5. **Set Permissions**: Ensures proper file ownership and permissions for Tomcat access
6. **Create Documentation**: Generates installation info and verification scripts

### Directory Structure

- **APEX Installation**: `/opt/apex/` - Complete APEX installation files
- **APEX Images**: `/opt/tomcat/webapps/i/` - APEX static images served by Tomcat
- **Context Configuration**: `/opt/tomcat/conf/Catalina/localhost/i.xml` - Tomcat context
- **Verification Script**: `/opt/apex/verify-apex-images.sh` - Installation verification

### URL Access

APEX images are accessible through the load balancer at:
- **HTTP**: `http://load-balancer-ip/i/` (redirects to HTTPS)
- **HTTPS**: `https://load-balancer-ip/i/`

Example URLs:
- APEX Logo: `https://load-balancer-ip/i/apex_ui/img/apex_logo.png`
- CSS Files: `https://load-balancer-ip/i/libraries/apex/minified/desktop.min.css`
- JavaScript: `https://load-balancer-ip/i/libraries/apex/minified/desktop.min.js`

## Configuration Variables

### Default Variables (ansible/roles/apex/defaults/main.yml)

```yaml
apex_version: "24.1"
apex_zip_url: "https://download.oracle.com/otn_software/apex/apex_{{ apex_version }}_en.zip"
apex_install_dir: "/opt/apex"
apex_images_dir: "{{ tomcat_home }}/webapps/i"
apex_context_path: "/i"
apex_user: "{{ tomcat_user }}"
apex_group: "{{ tomcat_group }}"
```

### Global Variables (ansible/group_vars/all.yml)

```yaml
apex_version: "24.1"
apex_install_dir: "/opt/apex"
apex_images_dir: "{{ tomcat_home }}/webapps/i"
apex_context_path: "/i"
cleanup_temp_files: false
```

## Security Features

### File Permissions
- All APEX files are owned by the Tomcat user (`tomcat:tomcat`)
- Images directory has read permissions for web serving
- Installation directory has appropriate access controls

### Tomcat Context Security
- Context configured with security valves
- Remote address validation
- Caching enabled for performance
- MIME type mappings for APEX resources

### Integration with Existing Security
- Works with existing firewall rules (port 8080 for Tomcat)
- Compatible with Network Security Groups (NSGs)
- Integrates with Web Application Firewall (WAF) policies
- Supports SSL/TLS termination at load balancer

## Testing and Verification

### Automated Testing

Use the provided test playbook to verify APEX installation:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini test-apex.yml
```

### Manual Verification

Run the verification script on private instances:

```bash
sudo /opt/apex/verify-apex-images.sh
```

### Test Checklist

The verification process checks:
- ✓ APEX installation directory exists
- ✓ APEX images directory exists and is populated
- ✓ Tomcat context configuration is present
- ✓ Key APEX subdirectories (apex_ui, libraries, themes) exist
- ✓ File permissions are correct
- ✓ URL accessibility (if Tomcat is running)
- ✓ Directory structure and file counts

## Performance Optimization

### Caching Configuration
- Tomcat context configured with caching enabled
- Cache TTL set to 24 hours (86400000ms)
- Maximum cache size: 100MB
- Reduces server load and improves response times

### Static Content Serving
- APEX images served as static content through Tomcat
- No dynamic processing required
- Efficient content delivery
- Browser caching supported

## Troubleshooting

### Common Issues

1. **Download Timeout**: APEX download may timeout on slow connections
   - Solution: Increase timeout in get_url task or pre-download files

2. **Disk Space**: APEX installation requires ~500MB disk space
   - Solution: Ensure adequate disk space before installation

3. **Permissions**: Incorrect file permissions may prevent access
   - Solution: Run verification script to check permissions

4. **Context Not Loading**: Tomcat context may not load properly
   - Solution: Check Tomcat logs and restart Tomcat service

### Log Locations

- **Tomcat Logs**: `/opt/tomcat/logs/catalina.out`
- **Installation Info**: `/opt/apex/APEX_INSTALLATION_INFO.txt`
- **Verification Script**: `/opt/apex/verify-apex-images.sh`

## Integration with ORDS

While this implementation focuses on APEX images, it complements Oracle REST Data Services (ORDS) installation:

- APEX images provide the UI resources for APEX applications
- ORDS provides the runtime engine for APEX applications
- Both work together to provide complete APEX functionality
- Images are served through Tomcat (port 8080)
- ORDS runtime is served through its own service (port 8888)

## Maintenance

### Updates
- To update APEX version, modify `apex_version` variable
- Re-run the Ansible playbook to install new version
- Old installations are preserved unless cleanup is enabled

### Cleanup
- Set `cleanup_temp_files: true` to remove temporary files after installation
- Temporary files are stored in `/tmp/apex/` during installation
- Installation files are preserved in `/opt/apex/` for reference

## WAF Policy Fix

As part of this implementation, the Web Application Firewall (WAF) policy syntax was also corrected:

### Issues Fixed
- Replaced invalid `=~` regex operator with `starts_with()` function
- Corrected `cidr_match()` function parameter order
- Updated all WAF access control rules with proper JMESPATH syntax

### WAF Rules Updated
- Marine data register access rules
- IPv4 and IPv6 CIDR matching
- Health check rules
- Default blocking rules

This ensures the WAF policy validates successfully and provides proper access control for the APEX-enabled application.