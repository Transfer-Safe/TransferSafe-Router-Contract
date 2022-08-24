// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

struct RouterConfig {
    mapping(address => address) chainlinkTokensAddresses;
    address chainlinkNativeTokenAddress;
}

abstract contract RouterConfigContract {
    RouterConfig config;
    uint256 chainId;

    constructor(uint256 _chainId) {
        chainId = _chainId;

        initializeChainlink();
    }

    function initializeChainlink() private {
        if (chainId == 80001) {
            // USDT
            config.chainlinkTokensAddresses[0x326C977E6efc84E512bB9C30f76E30c160eD06FB] = 0x92C09849638959196E976289418e5973CC96d645;
            // DAI
            config.chainlinkTokensAddresses[0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253] = 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046;
            // MATIC
            config.chainlinkNativeTokenAddress = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
            return;
        }
    }
}

