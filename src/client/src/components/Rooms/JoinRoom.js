import React, { useEffect, useState } from 'react'
import { joinRoom } from '../../services/rooms.js'
import * as io from "socket.io-client"
// import host from '../../services/host'

const socket = io("http://localhost:3001/api/test", {
  withCredentials: true,
//   extraHeaders: {
    // "my-custom-header": "abcd"
//   }
});
//   auth: {
    // token: "123"
//   },
//   query: {
    // "my-key": "my-value"
//   }


socket.on('connect', () => {
    console.log(socket.id)
})

const JoinRoom = () => {
    
    const [content, setContent] = useState('')
    // useEffect(() => {
    //     joinRoom()
    //     .then(res => {
    //             console.log(res)   
    //             setContent(res.text)})
    //     .catch(e => console.log(e))
    // }, [])
    return (
    <div>
        {/* <div>{content}</div> */}
    </div>
    )
    
    }
export default JoinRoom