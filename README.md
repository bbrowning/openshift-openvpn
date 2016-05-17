
# OpenVPN Local Development Proxy for OpenShift 3

This project is an OpenVPN server designed for OpenShift 3 to enable
development of one microservice and/or application locally while still
being able to access other services and/or applications running inside
OpenShift 3.

This requires you to have admin privileges (or at least enough
privileges to run a privileged Docker container) on the OpenShift 3
instance. The intended audience is a developer running OpenShift
locally or in some shared development environment.

**What works**

- DNS service discovery, assuming your OpenVPN client integrates with
  your OS to update nameserver settings (NetworkManager in Fedora does)

- Routing between your local machine and services running in
  OpenShift. This means Kubernetes API-based service discovery also
  works. The Kubernetes API server defaults to https://172.30.0.1 but
  may be different in your installation.

- Services running in OpenShift can discover and communicate with the
  service running on your local machine, assuming you've taken the
  steps near the end of this example to redirect traffic for that
  service locally.

**What kind of works**

- Service discovery via environment variables. For this to work,
  you'll need to copy/paste the environment variables from the
  openvpn-server and set them in your local environment (shell or
  IDE). You can get them via a command like `oc exec
  openvpn-server-2-0b90a env | grep -E '_PORT|_HOST'`

**What isn't tested yet**

- Windows and Mac OpenVPN clients - test and report back please!

**What doesn't work**

- Pinging hosts inside OpenShift from your local machine - stick to
  using curl or similar to verify communication with other services

- OpenVPN Certificate management - right now we generate new CA and
  server certificates when building the Docker image. This is why the
  instructions have you building the image in your OpenShift instead
  of pulling a published image. It would be possible via Secrets or
  other mechanisms to supply certificates, but this is a development
  tool and ease-of-use was chosen first.

## Example Usage

This example assumes you're using the Red Hat Developers
[Helloworld-MSA
application](https://htmlpreview.github.io/?https://github.com/redhat-helloworld-msa/helloworld-msa/blob/master/readme.html)
but can be adapted to other projects and environments.

**Login as an admin to give our user and serviceaccount permission to
  run privileged containers:**

    oc login 10.1.2.2:8443 -u admin -p admin
    oc project helloworld-msa
    oc adm policy add-scc-to-user privileged openshift-dev
    oc adm policy add-scc-to-user privileged -z default


**Then log back into your regular developer account:**

    oc login 10.1.2.2:8443 -u openshift-dev -p devel


**Now create our OpenVPN server:**

    git clone https://github.com/bbrowning/openshift-openvpn.git
    cd openshift-openvpn
    oc new-build --binary --name=openvpn-server
    oc start-build openvpn-server --from-dir=. --follow
    oc new-app openvpn-server -e OPENVPN_USER=foo,OPENVPN_PASS=bar
    oc patch dc openvpn-server -p '{"spec":{"template":{"spec":{"containers":[{"name":"openvpn-server","securityContext":{"privileged": true}}]}}}}'


**Wait for the openvpn-server pod to finish deploying**

    oc get pods -l app=openvpn-server

Wait until there's only a single entry returned with a status of
`Running` before moving on.


**Copy the CA Certificate somewhere locally**

    oc logs openvpn-server-YOUR-PODS-NAME

Copy the text starting from the `-----BEGIN CERTIFICATE-----` line up
to and including the `-----END CERTIFICATE-----` line to a file
locally called `openvpn-ca.crt`. If you're running a recent Fedora
with SELinux enabled and want to use NetworkManager as your OpenVPN
client, then you'll also need to save the file as
`~/.cert/openvpn-ca.crt` and then run:

    restorecon -R -v ~/.cert


**Use port-forwarding to access the OpenVPN server:**

    oc port-forward openvpn-server-YOUR-PODS-NAME 1194


**Connect your OpenVPN client to the OpenVPN server:**

On modern Linux distros, you should be able to use NetworkManager to
connect. You may need the `NetworkManager-openvpn-gnome` package first.

Create a new OpenVPN connection, using `localhost` as the gateway,
`TCP` instead of UDP (under Advanced settings in Fedora's
NetworkManager), password as the auth type and `foo` / `bar` as the
username and password combination (unless you changed it when
deploying the VPN server) and select your `openvpn-ca.crt` as the CA
Certificate. Under the IPv4 settings be sure to check `Use this
connection only for resources on its network`.

You can also connect manually with an OpenVPN client, but this method
doesn't automatically update /etc/resolv.conf and thus DNS service
resolution won't work out of the box. The [openvpn-update-resolv-conf
project](https://github.com/masterkorp/openvpn-update-resolv-conf) may
be useful here.

    sudo openvpn --client --remote localhost --dev tun --ca easy-rsa/keys/ca.crt --verb 3 --proto tcp-client --auth-user-pass

Mac and Windows clients should work as well but you'll need to
translate the instructions above for your client.


**Test your connection**

Assuming your Kubernetes API server is running on the default host,
make sure you can communicate with it through the VPN:

    curl -k https://172.30.0.1

To test DNS resolution, curl one of the helloworld-msa apps as well:

    curl http://aloha:8080


**Redirect a service's traffic into our local proxy**

Run the service you want to develop locally, listening on the same
port your OpenShift application does (probably 8080) and using 0.0.0.0
or the OpenVPN client's IP as your listening interface. Then, use the
following commands to redirect all traffic for that service through
the OpenVPN server and down to your local machine:

    oc export svc/namaste -o json > service_backup.json
    oc patch svc/namaste -p '{"spec": {"selector": {"$patch": "replace", "app": "openvpn-server"}}}'


**Switch from the proxy back to the real service**

When you're finished developing locally and want the service to run on
OpenShift again, just replace its definition with the backup we
created earlier.

    oc replace --force -f service_backup.json

## Subsequent Usage

Now that we've used the proxy once, to use it again for another
service just requires us to initiate the port-forward to the OpenVPN
server, connect with our already-configured client, and redirect the
other service's traffic to our local machine.
