# Live Application & Monitoring Links

The following links may be used for testing when running either locally or via a remote server instance (eg. AWS).

## PASOE Access

### OpenAPI / Swagger:

* Main Application - Contains the test-able endpoints:
  * http://127.0.0.1:7780/loadsuite/web/api/catalog/openapi
  * http://127.0.0.1:7780/loadsuite/static/catalog.html
* Montior Application - Reports on the main application:
  * http://127.0.0.1:7780/monitor/web/api/catalog/openapi
  * http://127.0.0.1:7780/monitor/static/catalog.html

### PASOE Health

Enablement of the **OpenEdge HealthScanner** is now automatic and will be available at the default port of 7785 for the instance.

* http://localhost:7785/health - HTTP Status Code Only: 200 = Healthy, 500 = Below Threshold
* http://localhost:7785/health?view=details - Detailed JSON view of probes
* http://localhost:7785/health?view=config - Dataset-friendly configuration
* http://localhost:7785/health?view=dataset - Dataset-friendly probe results

### Authentication - Direct HTML Forms

* http://127.0.0.1:7780/loadsuite/static/auth/login.html
* http://127.0.0.1:7780/loadsuite/static/auth/logout.html

#### Authentication - HTTP POST

The login and logout forms post to Spring Security endpoints under the same webapp context:

- Login POST URL: `http://127.0.0.1:7780/loadsuite/static/auth/j_spring_security_check`
- Logout POST URL: `http://127.0.0.1:7780/loadsuite/static/auth/j_spring_security_logout`
- Login form fields: `j_username`, `j_password`

Use a cookie jar (or equivalent session handling) so the authenticated session can be reused for logout or subsequent requests.

**cURL example**

```bash
# Login (stores session cookie)
curl -i -c cookies.txt -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "j_username=<username>&j_password=<password>" \
    http://127.0.0.1:7780/loadsuite/static/auth/j_spring_security_check

# Logout (sends same session cookie)
curl -i -b cookies.txt -X POST \
    http://127.0.0.1:7780/loadsuite/static/auth/j_spring_security_logout
```

If your PASOE deployment is configured with CSRF protection, include the CSRF token expected by your login/logout flow.

## Monitoring

### Database Stats:

While testing on select AWS instances the installed "thrasher" database is connectd to the Progress MDBA Dashboard. Data is collected at regular intervals and sent to a common backend accessible at the following locations.

* Internal: http://lxmarppmdb/cgi-bin/pm.cfg/DBstats.html?customer=8fFL2TffHH&dbname=QA_thrasher
* External: https://mdbadashboard.progress.com/neodash/db/detail?mdbaid=800 (Database: QA_thrasher)
