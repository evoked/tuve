import React, { useEffect, useState } from 'react'
import { getProfile, userLogout } from '../services/user'
import FormAction from './Buttons/FormAction'

const UserProfile = () => {
    const [response, setResponse] = useState('')
    const [user, setUser] = useState({username: '', created: '', email: ''})

    /* On component load, try to get user personal profile */
    useEffect(() => {
        setResponse('loading...')
        /* Get local user settings, sending authentication header as data */
        getProfile()
        .then(res => {
            /* Setting reponse to true when getProfile returns data */
            setResponse(true)
            setUser(res.user)
        })
        /* If error is thrown (no authentication), then auth will be kept false */
        .catch(e => {
            setResponse(`${e}`)
        })
    }, [])

    /* Logout button, calls userLogout function which clears all local and 
        serverside information about current login */
    return(
        <div>
            <h2>Profile:</h2>
            <div className="userCard">
                {
                user.username ? 
                <div> 
                    <p> {user.username} {user.created.slice(0,10)} {user.email}</p>
                    <FormAction type='decline' label='Logout' onClick={userLogout}/> 
                    <FormAction type='delete-account'>Delete Account</FormAction>
                </div>
            : 
            <p>{response}</p>}</div>
        </div>
    )
}



export default UserProfile
