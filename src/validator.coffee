_ = require 'lodash'

buffer = undefined

class ValidatorBase
    constructor: (@schema, @validatorMap, @logger) ->
        # Express makes us lose the context inside the middleware.
        # So we have to hack a bit.
        this.logger = @logger
        buffer = this

    requiredParameters: (baseUrl, method) ->
        # This only supports URL parameters as the last part.
        # A nicer solution should be considered.
        lastSlash = baseUrl.lastIndexOf '/'
        if baseUrl not in (Object.keys @schema) and lastSlash > 0
            baseUrl = baseUrl[0..baseUrl.lastIndexOf '/'] + ':id'
        return @schema?[baseUrl]?[method]

    validateObj: (obj, reqParams) ->
        reqParams ?= []
        obj = _.omit obj, (k for k in Object.keys obj when not obj[k]?)
        for key, val of obj
            if key not in reqParams
                err =
                    type : 'VALIDATORBASE_UNKNOWN_PARAMETER'
                    data :
                        key : key
                return err
            if @validatorMap[key]? val
                err =
                    type : 'VALIDATORBASE_INVALID_VALUE'
                    data :
                        key : key
                        val : val
                return err
        for key in reqParams
            if not obj[key]?
                err =
                    type : 'VALIDATORBASE_MISSING_PARAMETER'
                    data :
                        key : key
                return err
        return null

    validate: (req, res, next) ->
        reqParams = buffer.requiredParameters req.baseUrl, req.method
        o =
            url       : req.originalUrl
            baseUrl   : req.baseUrl
            method    : req.method
            reqParams : reqParams
            params    : req.params
            query     : req.query
            body      : req.body
            headers   : req.headers
            oauth     : req.oauth
        buffer.logger?.debug
            msg  : 'validatorbase: entered'
            data : o
        err = buffer.validateObj o.params, reqParams?.url
        if err
            e =
                msg  : 'validatorbase: error in url parameters'
                data : o
                err  : err
            buffer.logger?.err e
            return res
                .status 400
                .json e
        err = buffer.validateObj o.query, reqParams?.query
        if err
            e =
                msg  : 'validatorbase: error in query parameters'
                data : o
                err  : err
            buffer.logger?.err e
            return res
                .status 400
                .json e
        err = buffer.validateObj o.body, reqParams?.body
        if err
            e =
                msg  : 'validatorbase: error in body'
                data : o
                err  : err
            buffer.logger?.err e
            return res
                .status 400
                .json e
        next()

module.exports = (schema, validatorMap, logger) ->
    return new ValidatorBase schema, validatorMap, logger