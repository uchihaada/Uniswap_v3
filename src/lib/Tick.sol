// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./TickMath.sol";

library Tick {
    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // // the cumulative tick value on the other side of the tick
        // int56 tickCumulativeOutside;
        // // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // // only has relative meaning, not absolute — the value depends on when the tick is initialized
        // uint160 secondsPerLiquidityOutsideX128;
        // // the seconds spent on the other side of the tick (relative to the current tick)
        // // only has relative meaning, not absolute — the value depends on when the tick is initialized
        // uint32 secondsOutside;
        // // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    function tickSpacingToMaxLiquidityPerTick(
        int24 tickSpacing
    ) internal pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];
        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = liquidityDelta < 0
            ? liquidityGrossBefore - uint128(-liquidityDelta)
            : liquidityGrossBefore + uint128(liquidityDelta);
        require(liquidityGrossAfter <= maxLiquidity, "LO");
        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);
        if (liquidityGrossBefore == 0) {
            info.initialized = true;
        }
        info.liquidityGross = liquidityGrossAfter;

        info.liquidityNet = upper
            ? info.liquidityNet - liquidityDelta
            : info.liquidityNet + liquidityDelta;
    }

    function clear(
        mapping(int24 => Tick.Info) storage self,
        int24 tick
    ) internal {
        delete self[tick];
    }
}
