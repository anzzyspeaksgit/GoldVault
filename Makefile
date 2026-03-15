-include .env

.PHONY: all test clean deploy help install format

all: clean install build test

build:
	forge build

test:
	forge test

clean:
	forge clean

format:
	forge fmt

install:
	forge install

deploy:
	forge script script/DeployGoldVault.s.sol:DeployGoldVault --rpc-url https://data-seed-prebsc-1-s1.bnbchain.org:8545 --broadcast --verify -vvvv

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]"
