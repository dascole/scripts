role_name=dbkongrole
cluster_name=cre-testing
policy_name=kongpolicy
sa_name=kongsa
namespace=kongfused


# delete the stack in the console if you get Error: getting iamserviceaccounts: no output "Role1" in stack "eksctl-cre-testing-addon-iamserviceaccount-default-hgruber"
# you may have deleted the SA outside the CF stack
eksctl get iamserviceaccount --cluster $cluster_name
    #aws cloudformation delete-stack --stack-name stackname


# Get the ARN of the existing policy
policy_arn=$(aws iam list-policies | jq -r --arg pn "$policy_name" '.Policies[] | select(.PolicyName==$pn) | .Arn')
aws iam delete-policy --policy-arn $policy_arn
aws iam delete-role --role-name $role_name
eksctl delete iamserviceaccount $sa_name --cluster cre-testing

oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text  | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html
cat >rds-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "rds-db:connect",
            "Resource": "arn:aws:rdsdb:*:<ACCOUNT-NUM>:dbuser:<DB-INSTANCE-ID>/<DB-USER>"
        }
    ]
}
EOF

arn=$(aws iam create-policy --policy-name $policy_name --policy-document file://rds-policy.json | jq .Policy.Arn)

eksctl create iamserviceaccount \
   --name $sa_name \
   --namespace $namespace \
   --cluster $cluster_name \
   --role-name $role_name \
   --attach-policy-arn $arn \
   --approve


aws iam get-role --role-name $role_name --query Role.AssumeRolePolicyDocument

aws iam list-attached-role-policies --role-name $role_name --query AttachedPolicies[].PolicyArn --output text

export policy_arn=$(aws iam list-attached-role-policies --role-name $role_name --query AttachedPolicies[].PolicyArn --output text)

aws iam get-policy --policy-arn $policy_arn

aws iam get-policy-version --policy-arn $policy_arn --version-id v1


