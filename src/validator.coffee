_ = require 'lodash'

buffer = undefined

class ValidatorBase
    constructor: (@schema, @validatorMap, @logger) ->
        # Express makes us lose the context inside the middleware.
        # So we have to hack a bit.
        this.logger = @logger
        buffer = this

    requiredParameters: (baseUrl, method) ->
        # We cannot access req.route inside the middleware.
        # This should be done in a cleaner way nevertheless as the
        # current implementation is restricted to numbers.
        baseUrl = baseUrl.replace /\d+/g, ':id'
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
        reqParams = buffer.requiredParameters req.originalUrl, req.method
        o =
            url       : req.originalUrl
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