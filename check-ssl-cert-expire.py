#!/bin/python
import ssl, socket, datetime, sys, smtplib, string #imports default required
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

#domain is what we are going to make a connection to
#cert_repo is the CAN name that we expect to be returned in the certificate
#port is the TCP port on the other end we connect to
#warn is used when our ind_result['expire'] date is less than warn, we will throw an errors, throws exit code 1
#error is the same as above but throws exit code 2
#if you wanted you could add more things in here to check e.g. SAN/Serial Number
hostname = [{'domain': 'www.google.com', 'cert_resp': 'www.google.com', 'port': 443, 'warn': 14, 'error': 2},
            {'domain': 'www.facebook.com', 'cert_resp': '*d.facebook.com','port': 443, 'warn': 14, 'error': 2},
            {'domain': 'www.shouldnotworkk.com', 'cert_resp': 'www.shouldnotworkk.com.au','port': 4443, 'warn': 14, 'error': 2}
            ]

#converts my date time into a string for easier readability
def datetostring(obj):
    return obj.strftime("%Y-%m-%d %H:%M:%S")

def main(argv):
    ctx = ssl.create_default_context()
    today = datetime.datetime.utcnow() #current time in UTC since thats what certificate time is in
    date_format = r'%b %d %H:%M:%S %Y %Z' #used to parse the format provided by the certificate
    showSuccess = 1 #if you only want to see error messages in your output then make this 0
    results = [] #global results array

    #set email to 0 and you can leave all these as default otherwise fill in your information here
    email = 0 #1 to send or anything else to not send
    SMTP_TO = "notify@example.com.au" ##<<< Fill me in >>>
    SMTP_FROM = "monitor@example.com.au" ##<<< Fill me in >>>
    SMTP_HOST = "smtp.example.com.au" ##<<< Fill me in >>>
    SMTP_PORT = 25 ##<<< Fill me in >>>

    msg = MIMEMultipart()
    msg['To'] = SMTP_TO
    msg['From'] = SMTP_FROM
    SMTP_BODY = "<p>SSL Monitoring alerts for you are listed below:</p> \r\n"
    SMTP_SUBJECT = " SSL Alerting Monitor "
    SMTP_ALERT = "[SUCCESS]"
    htmlStart = SMTP_BODY + "<html><table><tr><th>Domain</th><th>Status</th><th>Expire</th><th>Serial</th><th>Issued To</th><th>Message</th></tr>"
    htmlBody = ""
    htmlEnd = "</table></html> \r\n "

    for host in hostname: #loops through each hostname we have to connect to
        ind_result = {}
        ind_result['domain'] = host['domain']
        ind_result['status'] = "ERROR" #set default to ERROR, if its a warning or OK i set it later
        warn_day = datetime.timedelta(days=host['warn']) #sets our timedelta for warnings
        error_day = datetime.timedelta(days=host['error']) #sets our timedate delta for errors
        ind_result['message'] = ""
        try:
            s = ctx.wrap_socket(socket.socket(), server_hostname=host['domain']) #creates the socket
            s.connect((host['domain'], host['port'])) #this creates the connection to the web server using our socket
            cert = s.getpeercert() #This gets the certificate data from the other side

            #sets variables used for logging and date mathmatics
            subject = dict(x[0] for x in cert['subject'])
            ind_result['expire'] = datetime.datetime.strptime(cert['notAfter'], date_format) #formats values in datetime format
            ind_result['begin'] = datetime.datetime.strptime(cert['notBefore'], date_format) #formats values in datetime format
            ind_result['serialNumber'] = cert['serialNumber'] #gets serial number
            ind_result['issued_to'] = subject['commonName'] #gets common name presented by certificate

            if ind_result['issued_to'] == host['cert_resp']: # checks to make sure the certificate CAN matches what we expected
                if today < ind_result['begin']: #the certificate being date is in the future
                    temp_msg = "Certificate beings in the future on: " + datetostring(ind_result['begin'])
                if today > ind_result['expire']:
                    temp_msg = "Certificate expired already on: " + datetostring(ind_result['expire'])
                elif today > (ind_result['expire'] - error_day):
                    temp_msg = "Certificate expires EXTREMELY soon on: " + datetostring(ind_result['expire'])
                elif today > (ind_result['expire'] - warn_day):
                    temp_msg = "Certificate expires VERY soon on: " + datetostring(ind_result['expire'])
                    ind_result['status'] = "WARNING"
                else:
                    ind_result['status'] = "OK"
                    temp_msg = "Certificate has no Errors or Warnings"
            else:
                temp_msg = "Certificate " + str(ind_result['issued_to']) + " was returned when we expected " + host['domain']
            ind_result['expire'] = datetostring(ind_result['expire'])
            ind_result['begin'] = datetostring(ind_result['begin'])
        except Exception as msgs: #set our values to default so they dont take the last variables assigned from previous check
            temp_msg = str(msgs)
            ind_result['expire'] = "N/A"
            ind_result['begin'] = "N/A"
            ind_result['serialNumber'] = "N/A"
            ind_result['issued_to'] = "N/A"
        s.close() #close the connection as we no longer need it
        ind_result['message'] = temp_msg
        htmlBody = htmlBody + "<tr><td>" + ind_result['domain'] + "</td><td>" + ind_result['status'] + "</td><td>" + ind_result['expire'] + "</td><td>" + ind_result['serialNumber'] + "</td><td>" + ind_result['issued_to'] + "</td><td>" + ind_result['message'] + "</tr></td>"
        results.append(ind_result)

    #sets our exit codes and SMTP subject alert
    if any(data['status'] == 'ERROR' for data in results):
        exitcode = 2
        SMTP_ALERT = "[ERRORS]"
    elif any(data['status'] == 'WARNING' for data in results):
        exitcode = 1
        SMTP_ALERT = "[WARNING]"

    if email == 1:
        try:
            msg['Subject'] = SMTP_ALERT + SMTP_SUBJECT
            msg.attach(MIMEText(str(htmlStart + htmlBody + htmlEnd), 'html'))
            SMTP_CONN = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
            SMTP_CONN.sendmail(SMTP_FROM, SMTP_TO, msg.as_string())
            SMTP_CONN.quit()
        except Exception as msgs:
            print("SMTP Error: " + str(msgs))
            exitcode = 2 #force an error since we could not send an email

    print(results)
    print("Exitcode: " + str(exitcode))
    sys.exit(exitcode)

if __name__ == "__main__":
   main(sys.argv[1:])
