#!/usr/bin/env node
// Generated by CoffeeScript 1.3.3
(function() {
  var AWS, dnsserver, port, server, zone;

  dnsserver = require('dnsserver');

  AWS = require('aws-sdk');

  zone = process.argv[2] || 'aws';

  port = process.argv[3] || 20561;

  server = dnsserver.createServer();

  server.bind(port, '127.0.0.1');

  console.log("Starting server on port " + port + " with zone ." + zone);

  server.on('request', function(req, res) {
    var ec2, ec2request, filter, hostname, matches, question, region, send_nx;
    question = req.question;
    console.log("" + question.name + ": DNS Query type: " + question.type + ", class: " + question["class"]);
    send_nx = function(reason) {
      if (reason == null) {
        reason = null;
      }
      console.log("" + question.name + ": DNS NX response sent: " + reason);
      res.header.rcode = 3;
      return res.send();
    };
    try {
      if (question.type === 1 && question["class"] === 1) {
        matches = question.name.match(RegExp("([a-zA-Z0-9-\\.]+?)\\.(?:([a-zA-Z0-9-]+)\\.)?" + zone));
        hostname = matches[1];
        region = matches[2];
        filter = hostname.match(/^i-/) ? {
          "Name": 'instance-id',
          'Values': [hostname]
        } : {
          "Name": 'tag:Name',
          'Values': [hostname]
        };
        console.log("" + question.name + ": Looking for instance " + hostname + " @ " + region);
        ec2 = new AWS.EC2();
        if (region) {
          ec2.setEndpoint("https://ec2." + region + ".amazonaws.com/");
        }
        ec2request = ec2.describeInstances({
          Filters: [filter]
        });
        ec2request.on('success', function(o) {
          o.data.Reservations.forEach(function(reservation) {
            return reservation.Instances.forEach(function(instance) {
              if (instance.PublicIpAddress) {
                res.addRR(question.name, 1, 1, 60, instance.PublicIpAddress);
                return console.log("" + question.name + ": Found at " + instance.PublicIpAddress);
              }
            });
          });
          res.send();
          return console.log("" + question.name + ": DNS response sent");
        });
        ec2request.on('error', function(err) {
          console.log("" + question.name + ": EC2 API error: " + err);
          return send_nx();
        });
        return ec2request.send();
      } else {
        throw "Unknown request";
      }
    } catch (e) {
      return send_nx(e);
    }
  });

  server.on('error', function(e) {
    return console.log(e);
  });

}).call(this);
