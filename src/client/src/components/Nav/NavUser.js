import React, { useState, useEffect } from 'react';
import {
    Link
  } from "react-router-dom"

const NavUser = () => {
    const [auth, setAuth] = useState(false)

    useEffect(() => {
        if(localStorage.getItem('token')) setAuth(true)
    }, [])
        return (
            <nav class="">
            <div class="z-50 sticky mx-auto w-screen min-w-full flex justify-between flex-row bg-purple-300 bg-opacity-50 rounded-b-lg">
                {auth ? 
                    <div class="mx-auto my-1">
                        <Link class="my-2 mx-5 px-1 transition duration-500 hover:bg-indigo-200 rounded-md" to="/discover"> Discover </Link>
                        <Link class="my-2 mx-5 px-1 transition duration-500 hover:bg-indigo-200 rounded-md" to="/connect"> Connect </Link>
                        <Link class="my-2 mx-5 px-1 transition duration-500 hover:bg-indigo-200 rounded-md" to="/settings"> Settings </Link>
                        <Link class="my-2 mx-5 px-1 transition duration-500 hover:bg-indigo-200 rounded-md" to="/profile">♥</Link>
                    </div> 
                    : 
                    <nav className="navbar-noauth">
                    <Link to="/">Home </Link>
                    <Link to="/users"> Users </Link>
                    <Link to="/register"> Register</Link>
                    </nav>
                }
            </div>
            </nav>
        )
    }

export default NavUser;
