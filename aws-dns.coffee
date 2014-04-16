#!/usr/bin/env coffee

dnsserver = require('dnsserver')
AWS = require('aws-sdk')

zone = (process.argv[2] or 'aws')
port = (process.argv[3] or 20561)

server = dnsserver.createServer()
server.bind(port, '127.0.0.1')

console.log "Starting server on port #{port} with zone .#{zone}"

server.on 'request', (req, res) -> 
  question = req.question
  console.log("#{question.name}: DNS Query type: #{question.type}, class: #{question.class}")
    
  send_nx = (reason=null) ->
    console.log "#{question.name}: DNS NX response sent: #{reason}"    
    res.header.rcode = 3
    res.send()    
  try 
    if question.type == 1 && question.class == 1
      matches = question.name.match(///([a-zA-Z0-9-\.]+?)\.(?:([a-zA-Z0-9-]+)\.)?#{zone}///)
      hostname = matches[1]
      region = matches[2]
      filter = if hostname.match /^i-/
        {"Name": 'instance-id', 'Values': [hostname]}
      else
        {"Name": 'tag:Name', 'Values': [hostname]}
      
      console.log "#{question.name}: Looking for instance #{hostname} @ #{region}"
    
      ec2 = new AWS.EC2();
      ec2.setEndpoint "https://ec2.#{region}.amazonaws.com/" if region
      
      ec2request = ec2.describeInstances(Filters: [filter])
      ec2request.on 'success', (o) ->
        o.data.Reservations.forEach (reservation) ->    
          reservation.Instances.forEach (instance) ->
            if instance.PublicIpAddress
              res.addRR(question.name, 1, 1, 60, instance.PublicIpAddress)
              console.log("#{question.name}: Found at #{instance.PublicIpAddress}")
        res.send()      
        console.log "#{question.name}: DNS response sent"
      
      ec2request.on 'error', (err) ->
        console.log "#{question.name}: EC2 API error: #{err}"
        send_nx()
        
      ec2request.send()
    else
      throw "Unknown request"
  catch e
    send_nx(e)
    
server.on 'error', (e) ->
  console.log e