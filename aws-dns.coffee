#!/usr/bin/env coffee

dnsserver = require('dnsserver')
AWS = require('aws-sdk')
ec2 = new AWS.EC2();

server = dnsserver.createServer()
server.bind(20561, '127.0.0.1')

server.on 'request', (req, res) -> 
  console.log("req = ", req)
  question = req.question
  
  if question.type == 1 && question.class == 1
    matches = question.name.match(/([a-zA-Z0-9-]+)\.aws/)
    hostname = matches[1]
    console.log hostname
    filter = if hostname.match /^i-/
      {"Name": 'instance-id', 'Values': [hostname]}
    else
      {"Name": 'tag:Name', 'Values': [hostname]}
      
    console.log "DNS request for #{hostname}"
      
    ec2request = ec2.describeInstances(Filters: [filter])
    ec2request.on 'success', (o) ->
      o.data.Reservations.forEach (reservation) ->    
        reservation.Instances.forEach (instance) ->
          if instance.PublicIpAddress
            res.addRR(question.name, 1, 1, 60, instance.PublicIpAddress)
      res.send()      
      console.log "DNS response sent"
      
    ec2request.on 'error', (err) ->
      console.log "DNS NX response sent"
      console.log(err)
      res.header.rcode = 3
    ec2request.send()
  else
    console.log "DNS NX response sent"    
    res.header.rcode = 3
    res.send()
    
server.on 'error', (e) ->
  console.log e