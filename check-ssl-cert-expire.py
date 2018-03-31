#!/bin/python
import ssl, socket, os, datetime, sys

hostname = [{'domain': 'www.google.com', 'port': 443, 'warn': 14, 'error': 2},
            {'domain': 'www.facebook.com', 'port': 443, 'warn': 14, 'error': 2},
           ]

def main(argv):
    ctx = ssl.create_default_context()
    today = datetime.datetime.utcnow()
    date_format = r'%b %d %H:%M:%S %Y %Z'
    showSuccess = 1 #if you only want to see error messages in your output then make this 0
    error = 0
    warn = 0

    for host in hostname:
        try:
            s = ctx.wrap_socket(socket.socket(), server_hostname=host['domain'])
            s.connect((host['domain'], host['port']))
            cert = s.getpeercert()

            #sets variables used for logging and date mathmatics
            subject = dict(x[0] for x in cert['subject'])
            expire = datetime.datetime.strptime(cert['notAfter'], date_format) #formats values in datetime format
            begin = datetime.datetime.strptime(cert['notBefore'], date_format) #formats values in datetime format
            serialNumber = cert['serialNumber'] #gets serial number
            issued_to = subject['commonName']
            warn_day =datetime.timedelta(days=host['warn'])
            error_day = datetime.timedelta(days=host['error'])

            if today < begin: #the certificate being date is in the future
                print("Error: " + host['domain'] + " (" + serialNumber + ") has a begin date of " + str(begin) + " which is in the future, the time is " + str(today))
                error += 1
            #handles errors if certificate has expired, expires in error_day OR in warn_day
            if today > (expire - error_day):
                print("Error: " + host['domain'] + " (" + serialNumber + ") has expired on: " + str(expire))
                error += 1
            elif today > (expire - error_day):
                print("Error: " + host['domain'] + " (" + serialNumber + ") will expire in less than " + str(host['error']) + " days on the: " + str(expire))
                error += 1
            elif today > (expire - warn_day):
                print("Warning: " + host['domain'] + " (" + serialNumber + ") will expire in less than " + str(host['warn']) + " days on the: " + str(expire))
                warn += 1
            else:
                if showSuccess == 1:
                    print("Success: " + host['domain'] + " (" + serialNumber + ") will NOT expire soon, expires on: " + str(expire))
        except Exception as msg:
            print("Error:" + str(msg) + " for " + host['domain']+":"+str(host['port']))

    if error == 0 and warn == 0:
        sys.exit(0)
    elif warn > 0:
        sys.exit(1)
    sys.exit(2)

if __name__ == "__main__":
   main(sys.argv[1:])
