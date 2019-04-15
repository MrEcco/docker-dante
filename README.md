# Dante

Just all-in-one build with libpam, libgss, libkrb5 and libupnp abilities.

## Configuration

### No auth

Just use this setting in sockd.conf:

```bash
socksmethod: none
```

### Username auth

Define in sockd.conf:

```bash
socksmethod: username
```

... and add users in container:

```bash
useradd -s /bin/false -Md /unexist <username> -p <password>
```
