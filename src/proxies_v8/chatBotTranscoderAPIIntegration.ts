import axios from 'axios'
import express from 'express'
import { axiosRequestConfig } from '../configs/request.config'
import { CONSTANTS } from '../utils/env'
import { logError, logInfo } from '../utils/logger'

export const chatBotTranscoderAPIIntegration = express.Router()

chatBotTranscoderAPIIntegration.use('/*', async (req: express.Request, res: express.Response) => {
    try {

        const baseUrl = removePrefix('/proxies/v8/chatbot/v3/', req.originalUrl)
        logInfo(`The url is... ${baseUrl} : originalUrl: ${req.originalUrl}`)
        const subPath = baseUrl.replace(/^\/+/, '')
        const url = `${CONSTANTS.APP_FUEL_API_URL}/${subPath}`
        const requestBody = req.body
        logInfo(`Chatbot Transcoder API Request -> URL: ${url}`)

        // Remove 'br' from request headers
        const requestHeaders = { ...req.headers }
        if (requestHeaders['accept-encoding']) {
            requestHeaders['accept-encoding'] = (requestHeaders['accept-encoding'] as string)
                .split(',')
                .map(enc => enc.trim())
                .filter(enc => enc !== 'br')
                .join(', ')
        }
        if (requestHeaders['content-encoding']) {
            requestHeaders['content-encoding'] = (requestHeaders['content-encoding'] as string)
                .split(',')
                .map(enc => enc.trim())
                .filter(enc => enc !== 'br')
                .join(', ')
        }

        const axiosConfig = {
            headers: {
                'Content-Type': 'application/json',
                ...requestHeaders,
            },
            ...axiosRequestConfig,
        }

        let response
        if (req.method === 'GET') {
            response = await axios.get(url, axiosConfig)
        } else if (req.method === 'POST') {
            response = await axios.post(url, requestBody, axiosConfig)
        } else if (req.method === 'PUT') {
            response = await axios.put(url, requestBody, axiosConfig)
        } else if (req.method === 'DELETE') {
            response = await axios.delete(url, axiosConfig)
        } else {
            return res.status(405).send({ error: `Method ${req.method} not supported` })
        }

        // Remove 'br' from response headers
        const responseHeaders = { ...response.headers }
        if (responseHeaders['content-encoding']) {
            responseHeaders['content-encoding'] = (responseHeaders['content-encoding'] as string)
                .split(',')
                .map(enc => enc.trim())
                .filter(enc => enc !== 'br')
                .join(', ')
        }
        if (responseHeaders['accept-encoding']) {
            responseHeaders['accept-encoding'] = (responseHeaders['accept-encoding'] as string)
                .split(',')
                .map(enc => enc.trim())
                .filter(enc => enc !== 'br')
                .join(', ')
        }

        // Set filtered headers to response
        Object.keys(responseHeaders).forEach(key => {
            if (responseHeaders[key]) {
                res.setHeader(key, responseHeaders[key])
            }
        })

        return res.status(response.status).send(response.data)
    } catch (error) {
        logError(`Error in chatBotTranscoderAPIIntegration`, error)
        return res.status(500).send({ error: 'Failed to fetch data from chatbot transcoder API' })
    }
})

function removePrefix(prefix: string, s: string): string {
  return s.startsWith(prefix) ? s.substring(prefix.length) : s
}
