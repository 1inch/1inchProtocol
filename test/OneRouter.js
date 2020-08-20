const { ether, BN } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const money = {
    ether,
    eth: ether,
    zero: ether('0'),
    oneWei: ether('0').addn(1),
    weth: ether,
    dai: ether,
    usdc: (value) => ether(value).divn(1e6).divn(1e6),
};

function linear (bn, n) {
    const arr = [];
    for (let i = 0; i < n; i++) {
        arr.push(bn.muln(i + 1).divn(n));
    }
    return arr;
}

// async function trackReceivedToken (token, wallet, txPromise) {
//     const preBalance = web3.utils.toBN(
//         (token === constants.ZERO_ADDRESS)
//             ? await web3.eth.getBalance(wallet)
//             : await token.balanceOf(wallet),
//     );

//     let txResult = await txPromise();
//     if (txResult.receipt) {
//         // Fix coverage since testrpc-sc gives: { tx: ..., receipt: ...}
//         txResult = txResult.receipt;
//     }
//     let txFees = web3.utils.toBN('0');
//     if (wallet.toLowerCase() === txResult.from.toLowerCase() && token === constants.ZERO_ADDRESS) {
//         const receipt = await web3.eth.getTransactionReceipt(txResult.transactionHash);
//         const tx = await web3.eth.getTransaction(receipt.transactionHash);
//         txFees = web3.utils.toBN(receipt.gasUsed).mul(web3.utils.toBN(tx.gasPrice));
//     }

//     const postBalance = web3.utils.toBN(
//         (token === constants.ZERO_ADDRESS)
//             ? await web3.eth.getBalance(wallet)
//             : await token.balanceOf(wallet),
//     );

//     return postBalance.sub(preBalance).add(txFees);
// }

const OneRouter = artifacts.require('OneRouter');
const OneRouterView = artifacts.require('OneRouterView');
// const Token = artifacts.require('TokenMock');

const DISABLE_ALL = new BN('100000000000000000000000000000000', 16);
const DISABLE_UNISWAP_V1 = new BN('1', 16);
const DISABLE_UNISWAP_V2 = new BN('2', 16);
const DISABLE_UNISWAP_ALL = DISABLE_UNISWAP_V1.add(DISABLE_UNISWAP_V2);
const DISABLE_KYBER_ALL = new BN('200000000000000000000000000000000', 16);
const DISABLE_CURVE_ALL = new BN('400000000000000000000000000000000', 16);

contract('OneRouter', function ([_, wallet1, wallet2]) {
    before(async function () {
        this.routerView = await OneRouterView.new();
        this.router = await OneRouter.new(this.routerView.address);
    });

    describe('Uniswap V1', async function () {
        it('should give DAI amount for 1 ETH', async function () {
            const result = await this.router.getSwapReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                [money.eth('1')],
                {
                    destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                    flags: DISABLE_ALL.add(DISABLE_UNISWAP_V1).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('100'));
            expect(result.estimateGasAmounts[0]).to.be.equal('60000');
            expect(result.distributions[0][0]).to.be.equal('1');
        });

        it('should give ETH amount for 1 DAI', async function () {
            const result = await this.router.getSwapReturn(
                '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                [money.dai('1')],
                {
                    destToken: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                    flags: DISABLE_ALL.add(DISABLE_UNISWAP_V1).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.lessThan(money.dai('0.0025'));
            expect(result.estimateGasAmounts[0]).to.be.equal('60000');
            expect(result.distributions[0][0]).to.be.equal('1');
        });
    });

    describe('Uniswap V2', async function () {
        it('should give DAI amount for 1 ETH', async function () {
            const result = await this.router.getSwapReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                [money.eth('1')],
                {
                    destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                    flags: DISABLE_ALL.add(DISABLE_UNISWAP_V2).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('100'));
            expect(result.estimateGasAmounts[0]).to.be.equal('50000');
            expect(result.distributions[0][1]).to.be.equal('1');
        });

        it('should give ETH amount for 1 DAI', async function () {
            const result = await this.router.getSwapReturn(
                '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                [money.dai('1')],
                {
                    destToken: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                    flags: DISABLE_ALL.add(DISABLE_UNISWAP_V2).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.lessThan(money.dai('0.0025'));
            expect(result.estimateGasAmounts[0]).to.be.equal('50000');
            expect(result.distributions[0][1]).to.be.equal('1');
        });
    });

    describe('Kyber', async function () {
        it('should give DAI amount for 1 ETH', async function () {
            const result = await this.router.getSwapReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                [money.eth('1')],
                {
                    destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                    flags: DISABLE_ALL.add(DISABLE_KYBER_ALL).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('100'));
            expect(result.estimateGasAmounts[0]).to.be.equal('100000');
        });

        it('should give ETH amount for 1 DAI', async function () {
            const result = await this.router.getSwapReturn(
                '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                [money.dai('1')],
                {
                    destToken: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                    flags: DISABLE_ALL.add(DISABLE_KYBER_ALL).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.lessThan(money.dai('0.0025'));
            expect(result.estimateGasAmounts[0]).to.be.equal('100000');
        });
    });

    describe('Curve', async function () {
        it('should give DAI amount for 1 USDC', async function () {
            const result = await this.router.getSwapReturn(
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
                [money.usdc('1')],
                {
                    destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                    flags: DISABLE_ALL.add(DISABLE_CURVE_ALL).toString(),
                    destTokenEthPriceTimesGasPrice: 0,
                    disabledDexes: [],
                },
            );

            expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('0.9'));
            expect(result.estimateGasAmounts[0]).to.be.equal('720000');
        });
    });

    describe('Aggregation', async function () {
        it('should give DAI amount for 1000 ETH over USDC', async function () {
            const result = await this.router.getPathReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                [money.eth('1000')],
                {
                    swaps: [
                        {
                            destToken: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
                            flags: DISABLE_ALL.add(DISABLE_UNISWAP_ALL).toString(),
                            destTokenEthPriceTimesGasPrice: 0,
                            disabledDexes: [],
                        },
                        {
                            destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                            flags: DISABLE_ALL.add(DISABLE_CURVE_ALL).toString(),
                            destTokenEthPriceTimesGasPrice: 0,
                            disabledDexes: [],
                        }
                    ]
                }
            );

            console.log('result', JSON.stringify(result));
            //expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('100'));
            //expect(result.estimateGasAmounts[0]).to.be.equal('100000');
        });

        it('should give DAI amount for 1000 ETH', async function () {
            const result = await this.router.getMultiPathReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
                linear(money.eth('10000'), 10),
                [
                    {
                        swaps: [
                            {
                                destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                                flags: DISABLE_ALL.add(DISABLE_UNISWAP_ALL).toString(),
                                destTokenEthPriceTimesGasPrice: 0,
                                disabledDexes: [],
                            }
                        ]
                    },
                    {
                        swaps: [
                            {
                                destToken: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
                                flags: DISABLE_ALL.add(DISABLE_UNISWAP_ALL).toString(),
                                destTokenEthPriceTimesGasPrice: 0,
                                disabledDexes: [],
                            },
                            {
                                destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                                flags: DISABLE_ALL.add(DISABLE_CURVE_ALL).toString(),
                                destTokenEthPriceTimesGasPrice: 0,
                                disabledDexes: [],
                            }
                        ]
                    },
                    {
                        swaps: [
                            {
                                destToken: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
                                flags: DISABLE_ALL.add(DISABLE_UNISWAP_ALL).toString(),
                                destTokenEthPriceTimesGasPrice: 0,
                                disabledDexes: [],
                            },
                            {
                                destToken: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
                                flags: DISABLE_ALL.add(DISABLE_CURVE_ALL).toString(),
                                destTokenEthPriceTimesGasPrice: 0,
                                disabledDexes: [],
                            }
                        ]
                    }
                ]
            );

            console.log('result', JSON.stringify(result));
            //expect(result.returnAmounts[0]).to.be.bignumber.greaterThan(money.dai('100'));
            //expect(result.estimateGasAmounts[0]).to.be.equal('100000');
        });
    });
});
