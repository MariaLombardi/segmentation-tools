myaddress = 'icubmatlab@gmail.com';
mypassword = 'icubmatlabAdmin';

setpref('Internet','E_mail',myaddress);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',myaddress);
setpref('Internet','SMTP_Password',mypassword);

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', ...
                  'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

try
    startup;
    bkg_numbs = 7000;
    gpu_id = 1;
    sigmas = [20 22 24 26 28 30 40 70];
    lambdas = [0.001 0.0001 0.00001 0.000001 0.0000001];
    Nystrom_centres = 4000;
    iterations = 150;
    script_FALKON_on_voc2007_TASK2_trainval_ZF_7000(bkg_numbs, sigmas, lambdas, Nystrom_centres, iterations, gpu_id);
    sendmail({'elisa.maiettini@gmail.com'}, ['Done: trainval of TASK1 features for TASK2']);
    quit;
catch error_struct
    sendmail({'elisa.maiettini@gmail.com'},'Error trainval of TASK1 features for TASK2!', [error_struct.message char(10) 'in file: ' error_struct.stack(1).file char(10) 'at line: ' num2str(error_struct.stack(1).line)]);
    quit;
end


