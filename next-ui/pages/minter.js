import { useState, useEffect, useReducer, useCallback } from "react";

import Head from "next/head";

import { ethers } from "ethers"
import Web3Modal from "web3modal"
import WalletConnectProvider from '@walletconnect/web3-provider'


import ScienceFund from "../artifacts/contracts/ScienceFund.sol/ScienceFund.json";

import BigButton from "../components/bigButton";
import ConnectWallet from "../components/connectWallet";
import CheckoutScreen from "../components/checkoutScreen";
import Summary from "../components/summary";
import WhyNFT from "../components/whyNFT";
import HowItWorks from "../components/howitworks";
import TraceScreen from "../components/traceScreen";
import Footer from "../components/footer";


const contractAddress = process.env.NEXT_PUBLIC_RINKEBY_CONTRACT_ADDRESS;
console.log(contractAddress);

const providerOptions = {
    walletconnect: {
        package: WalletConnectProvider, // required
        options: {
            infuraId: "INFURA_ID" // required
        }
    }
}

let web3Modal
if (typeof window !== 'undefined')
{
    web3Modal = new Web3Modal({
        network: 'mainnet',
        cacheProvider: true,
        providerOptions,
    })

}


const initialState = {
    provider: null,
    web3Provider: null,
    address: null,
    network: null,
    contract: null,
}

function reducer(state, action)
{
    switch (action.type)
    {
        case 'SET_WEB3_PROVIDER':
            return {
                ...state,
                provider: action.provider,
                web3Provider: action.web3Provider,
                address: action.address,
                network: action.network,
                contract: action.contract
            }
        case 'RESET_WEB3_PROVIDER':
            return initialState
        default:
            throw new Error()
    }

}




export default function Minter()
{

    const [state, dispatch] = useReducer(reducer, initialState)
    const { provider, web3Provider, address, network, contract } = state

    const [startCheckout, setStartCheckout] = useState(false);
    const [startTrace, setStartTrace] = useState(false);

    const connect = async () =>
    {
        const provider = await web3Modal.connect()
        const web3Provider = new ethers.providers.Web3Provider(provider)
        const signer = web3Provider.getSigner()
        const address = await signer.getAddress()
        const network = await web3Provider.getNetwork()

        // conncet to contract on the network
        const contract = new ethers.Contract(process.env.NEXT_PUBLIC_RINKEBY_CONTRACT_ADDRESS, ScienceFund.abi, web3Provider);
        const sftContract = contract.connect(signer);

        dispatch({
            type: 'SET_WEB3_PROVIDER',
            provider: provider,
            web3Provider: web3Provider,
            address: address,
            network: network.name,
            contract: sftContract
        })
    }

    const disconnect = useCallback(async function ()
    {
        await web3Modal.clearCachedProvider()
        if (provider?.disconnect && typeof provider.disconnect === 'function')
        {
            await provider.disconnect()
        }
        dispatch({
            type: 'RESET_WEB3_PROVIDER',
        })
    }, [provider])

    // auto load cached provider
    useEffect(() =>
    {
        if (web3Modal.cacheProvider)
        {
            connect()
        }
    }, [connect])


    //listen to events specified by EIP-1193
    useEffect(() =>
    {
        if (provider?.on)
        {
            // https://docs.ethers.io/v5/concepts/best-practices/#best-practices--network-changes
            provider.on('chainChanged', () => { window.location.reload() })

            //subscription cleanup
            return () =>
            {
                if (provider.removeListener)
                {
                    provider.removeListener('chainChanged', () => { window.location.reload() })
                }
            }
        }

    }, [provider])



    return (
        <div className='w-screen mx-auto font-serif overflow-x-hidden'>
            <Head>
                <title>Science Fund</title>
                <meta name='description' content='Science Fund Minter App' />
                <link rel='icon' href='/favicon.ico' />
            </Head>
            <div className='w-screen mx-auto'>
                <section className='relative mx-auto bg-gradient-to-tr from-slate-50 to-emerald-50  w-screen'>
                    {web3Provider ?
                        <ConnectWallet
                            onClick={disconnect}
                            label='Disconnect'
                            network={network}
                        />
                        :
                        <ConnectWallet
                            onClick={connect}
                            label='Connect Wallet'
                            network={network}
                        />
                    }

                    <div className='text-center text-white mx-auto px-10 py-48  max-w-screen-md	 w-min-96 h-min-96 md:w-3/4 sm:w-7/8'>

                        <h1 className='font-serif text-stone-700 text-3xl uppercase mb-2 font-bold tracking-wide'>
                            Science Fund Token
                        </h1>
                        <p className='mb-4 text-stone-500 text-lg font-thin font-sans px-2'>
                            the immutable permanent record
                            of your contribution to the future of science
                        </p>


                        <div className="mx-auto bg-white rounded-2xl shadow-2xl py-2 px-4">

                            <div className='block mx-auto text-left '>
                                <p className='text-gray-800 text-xl font-bold font-serif pl-2 mb-2'>
                                    Funding Pool
                                </p>
                                <select
                                    className='w-full h-20 max-w-64 mx-auto rounded-xl bg-slate-100 text-gray-700 text-xl border-transparent '>
                                    <option className="p-0">Pandemic Preparedness</option>
                                    <option value>Science Fund General Pool</option>
                                </select>
                            </div>

                            <div className='block mx-auto text-left '>
                                <p className='text-gray-800 text-xl font-bold font-serif pl-2 mb-2'>
                                    Amount
                                </p>
                                <div className="flex justify-items-stretch">
                                    <div>
                                        <input
                                            type='number'
                                            min='0.3'
                                            name='value'
                                            className={"w-full h-20 max-w-64 mx-auto rounded-xl bg-slate-100 text-gray-700 text-xl border-transparent"}
                                            placeholder='0.3'

                                        />
                                        <p className={'text-2xs italic text-gray-900'}>Minimum of 0.3 ETH is required.</p>
                                    </div>
                                    <div className="text-right">
                                        <span className='text-gray-900 text-xs font-light'>
                                            {Math.round(3600 * 0.01 * 100) / 100} USD
                                        </span>
                                        <span className="text-gray-900 mx-2 text-xl">ETH</span>
                                    </div>
                                </div>
                            </div>






                            <div className='block mx-auto text-left '>

                                <button className='w-full h-14 my-2 max-w-64 mx-auto rounded-xl bg-emerald-100 text-emerald-700 text-xl border-transparent'>
                                    <h2 >Mint Token</h2>
                            </button>
                            </div>
                        </div >




                    </div>


                </section >

            </div >
        </div >
            /* {
                    startCheckout && contract && <CheckoutScreen
                        close={() =>
                        {
                            setStartCheckout(false);
                        }}
                        contract={contract}
                        account={address}
                        network={network}
                    />
                }

                {
                    startTrace && web3Provider && <TraceScreen
                        close={() =>
                        {
                            setStartTrace(false);
                        }}
                        contract={contract}
                        account={address}
                        network={network}
                    />
                } */


        /* <Footer /> */

    );
}
