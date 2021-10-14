import express from 'express'

let rooms = new Array()

module.exports.connectToQueue = async (req, res) => {
    if(!req.headers.authorization) throw(new Error('no auth'))
    let user = res.locals.user
    console.log(user)
}