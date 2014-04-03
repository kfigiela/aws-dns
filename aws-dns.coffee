#!/usr/bin/env coffee

dnsserver = require('dnsserver')
AWS = require('aws-sdk')

zone = (process.argv[2] or 'aws')
port = (process.argv[3] or 20561)

server = dnsserver.createServer()
server.bind(port, '127.0.0.1')

console.log "Starting server on port #{port} with zone .#{zone}"

server.on 'request', (req, res) -> 
  console.log("req = ", req)
  question = req.question
  try 
    if question.type == 1 && question.class == 1
      matches = question.name.match(///([a-zA-Z0-9-]+)\.(?:([a-zA-Z0-9-]+)\.)?#{zone}///)
      console.log(matches)
      hostname = matches[1]
      region = matches[2]
      filter = if hostname.match /^i-/
        {"Name": 'instance-id', 'Values': [hostname]}
      else
        {"Name": 'tag:Name', 'Values': [hostname]}
      
      console.log "DNS request for #{hostname} @ #{region}"
    
      ec2 = new AWS.EC2();
      ec2.setEndpoint "https://ec2.#{region}.amazonaws.com/" if region
      
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
  catch e
    console.log(e)
    console.log "DNS NX response sent"    
    res.header.rcode = 3
    res.send()
    
server.on 'error', (e) ->
  console.log e