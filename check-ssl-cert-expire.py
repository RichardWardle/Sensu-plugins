#!/bin/python
import ssl, socket, datetime, sys #imports default required

#domain is what we are going to make a connection to
#cert_repo is the CAN name that we expect to be returned in the certificate
#port is the TCP port on the other end we connect to
#warn is used when our expire date is less than warn, we will throw an errors, throws exit code 1
#error is the same as above but throws exit code 2
#if you wanted you could add more things in here to check e.g. SAN/Serial Number
hostname = [{'domain': 'www.google.com', 'cert_resp': 'www.google.com', 'port': 443, 'warn': 14, 'error': 2},
            {'domain': 'www.facebook.com', 'cert_resp': '*.facebook.com','port': 443, 'warn': 14, 'error': 2},
           ]

def main(argv):
    ctx = ssl.create_default_context()
    today = datetime.datetime.utcnow() #current time in UTC since thats what certificate time is in
    date_format = r'%b %d %H:%M:%S %Y %Z' #used to parse the format provided by the certificate
    showSuccess = 1 #if you only want to see error messages in your output then make this 0
    error = len(hostname) #errors we have is set to the amount of domains we have. We will if no errors subtract from this
    warn = error #warnings we is also set to the same amount as errors since we will subtract

    for host in hostname: #loops through each hostname we have to connect to
        try:
            warn_day = datetime.timedelta(days=host['warn']) #sets our timedelta for warnings
            error_day = datetime.timedelta(days=host['error']) #sets our timedate delta for errors
            s = ctx.wrap_socket(socket.socket(), server_hostname=host['domain'])
            s.connect((host['domain'], host['port'])) #this creates the connection to the web server
            cert = s.getpeercert() #This gets the certificate data from the other side

            #sets variables used for logging and date mathmatics
            subject = dict(x[0] for x in cert['subject'])
            expire = datetime.datetime.strptime(cert['notAfter'], date_format) #formats values in datetime format
            begin = datetime.datetime.strptime(cert['notBefore'], date_format) #formats values in datetime format
            serialNumber = cert['serialNumber'] #gets serial number
            issued_to = subject['commonName'] #gets common name presented by certificate

            if issued_to == host['cert_resp']: # checks to make sure the certificate CAN matches what we expected
                host_string = str(host['domain'] + " [" + serialNumber + "] ")
                if today < begin: #the certificate being date is in the future
                    print("Error: " + host_string + " has a begin date of " + str(begin) + " which is in the future, the time is " + str(today))
                #handles errors if certificate has expired, expires in error_day OR in warn_day
                if today > expire:
                    print("Error: " + host_string + ") has expired on: " + str(expire))
                elif today > (expire - error_day):
                    print("Error: " + host_string + ") will expire on: " + str(expire))
                elif today > (expire - warn_day):
                    print("Warning: " + host_string + ") will expire on: " + str(expire))
                else:
                    warn -= 1
                    error -= 1
                    if showSuccess == 1:
                        print("Success: " + host_string + ") will NOT expire soon, expires on: " + str(expire))
            else:
                print("Error: " + str(issued_to) + " (" + serialNumber + ") was returned when we expected " + host['domain'])
        except Exception as msg:
            print("Error:" + str(msg) + " for " + host['domain']+":"+str(host['port']))

    if error == 0 and warn == 0: #means we had no errors or warnings since our value is back at 0
        sys.exit(0) #exit with 0 which is good
    elif error > 0: # if errors are greater than 0 we had need throw a exit code 2
        sys.exit(2)
    sys.exit(1) #at this point if we have no errors we must have a warning so exit code 1

if __name__ == "__main__":
   main(sys.argv[1:])
