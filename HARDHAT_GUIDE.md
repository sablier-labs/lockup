### Install requirements

```shell
bun install
```

### Clean previous builds

```shell
bun hardhat clean
```

### Compile contracts

```shell
bun hardhat compile --network $NETWORK
```

### Deploy contracts

```shell
bun hardhat run --network $NETWORK deploy/deploy.ts
```

### Verify contracts

```shell
bun hardhat verify --network $NETWORK $DEPLOYMENT_ADDRESS
```
