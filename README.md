# AppAuth with Dynamic Client Registration

An extended iOS AppAuth code example using authenticated Dynamic Client Registration.\
This improves the mobile app's security as described in [Mobile Best Practices](https://curity.io/resources/learn/oauth-for-mobile-apps-best-practices/).

## Code Example Article

The [Tutorial Walkthrough](https://curity.io/resources/learn/resources/appauth-dcr) explains the complete configuration and behavior.

## Prerequisites

Ensure that Docker Desktop and ngrok are installed.\
Then copy a `license.json` file for the Curity Identity Server into the root folder.

## Quick Start

Deploy the Curity Identity Server via Docker with settings preconfigured for DCR.\
An ngrok tunnel enables mobile connectivity to the Identity Server's endpoints.

```bash
./start-idsvr.sh
```

In Xcode run the app by opening the root folder.\
When prompted to sign in, do so as the following preconfigured user account:

- User: `demouser`
- Password: `Password1`

## User Experience

When the user first runs the app there is a prompt to authenticate.\
This gets an initial access token with the `dcr` scope.\
This is then used to create a Dynamic Client, which returns a Client ID and Client Secret.

![images](/images/registration-view.png)

The user must then authenticate again, and this is automatic via Single Sign On.\
On all subsequent authentication requests the user only needs to sign in once:

![images](/images/unauthenticated-view.png)

Once authenticated, the user is moved to the authenticated view.\
The demo app simply allows other OAuth lifecycle events to be tested.

![images](/images/authenticated-view.png)

## Manage Registration Details

To view all registered mobile instances, first connect to the Identity Server's SQL database:

```bash
export DB_CONTAINER_ID=$(docker container ls | grep curity-data | awk '{print $1}')
docker exec -it $DB_CONTAINER_ID bash -c "export PGPASSWORD=Password1 && psql -p 5432 -d idsvr -U postgres"
```

Then query the details of the dynamically registered mobile clients:

```bash
select * from dynamically_registered_clients;
```

## Teardown

Run the following command to free Docker resources:

```bash
./stop-idsvr.sh
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
