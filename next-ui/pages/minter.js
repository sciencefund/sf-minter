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


    const traceScreen = () =>
    {
        //start trace screen
        setStartTrace(true);

        if (!address)
        {
            connect();
        }
    };



    return (
        <div className='w-screen mx-auto font-serif overflow-x-hidden'>
            <Head>
                <title>Science Fund</title>
                <meta name='description' content='Science Fund Minter App' />
                <link rel='icon' href='/favicon.ico' />
            </Head>
            <div className='w-screen mx-auto'>
                <section className='relative mx-auto bg-gradient-to-r from-gray-900 via-green-700 to-gray-900 bg-opacity-10 w-screen'>
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

                    <div className='text-center text-white mx-auto w-3/4 py-48 h-min-96'>


                        <h1 className='text-grey-900 text-3xl uppercase mb-6 font-bold tracking-wide'>
                            Science Fund Tokens
                        </h1>
                        <p className='text-grey-800 text-1xl thin mb-4 '>
                            An immutable, permanent record
                            of your contribution to Science.
                        </p>



                        <div className="w-96 mx-auto ">

                            <div className='block my-8 text-center mx-auto text-left bg-green-700 p-2 rounded-2xl shadow-2xl'>
                                <p className='text-gray-100 text-left w-4/5 max-w-64 text-base font-semibold '>
                                    Funding Pool
                                </p>
                                <select
                                    className='w-full max-w-64 mx-auto my-8 rounded-xl bg-gray-900 text-sm'>
                                    <option >Pandemic Preparedness</option>
                                    <option value>Science Fund General Pool</option>
                                </select>
                            </div>


                            <div className='block my-8 text-center mx-auto text-left bg-green-700 p-2 rounded-2xl shadow-2xl'>
                                <p className='text-gray-100 text-left w-4/5 max-w-64 text-base font-semibold '>
                                    Amount
                                </p>
                                <div className="flex justify-items-stretch">
                                    <div className="text-left">
                                        <input
                                            type='number'
                                            min='0.3'
                                            name='value'
                                            className={`max-w-32 pl-5 py-1 rounded bg-gray-100`}
                                            placeholder='0.3'

                                        />
                                        <p className={'text-2xs italic text-gray-200'}>Minimum of 0.3 ETH is required.</p>
                                    </div>
                                    <div className="text-right">
                                        <span className='text-gray-100 text-xs font-light'>
                                            {Math.round(3600 * 0.01 * 100) / 100} USD
                                        </span>
                                        <span className="text-gray-100 mx-2 text-xl">ETH</span>
                                    </div>
                                </div>
                            </div>




                            <button className='bg-green-900 text-white w-2/3 hover:bg-gray-700 py-2 px-4 my-8 rounded'>
                                <h2 >Mint</h2>
                            </button>

                        </div >




                    </div>

                    <div className="h-18">
                    </div>
                </section >


                {
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
                }

            </div >
            <Footer />
        </div >
    );
}