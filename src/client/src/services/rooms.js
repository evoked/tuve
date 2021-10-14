import axios from "axios"
import host from './host'

const joinRoom = async (req, res) => {
    let response = await axios.get(`${host.HOST}${host.PORT}/api/test`)
    .catch(e => {
        throw new Error('no auth')
    })
    return response.data
}

export { joinRoom }