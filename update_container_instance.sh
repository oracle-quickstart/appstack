#!/bin/sh
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# drain backend from backend set
OUTPUT=$(oci lb backend update --backend-name $1 --backend-set-name $2 --backup false --drain true --load-balancer-id $3 --offline false --weight 1 --wait-for-state SUCCEEDED --wait-for-state FAILED)
if [[ $OUTPUT == *"FAILED"* ]] ; then
  exit 1
else
  echo "load balancer drained backend: $1"
fi

# update backend
OUTPUT=$(oci container-instances container-instance restart --container-instance-id $4 --wait-for-state SUCCEEDED --wait-for-state FAILED)
if [[ $OUTPUT == *"FAILED"* ]] ; then
  exit 1
else
  echo "updated container instance: $4"
fi

# wait for container instance to come up again
sleep 30
OUTPUT="FAILED"
i=0
while [[ $OUTPUT != *"OK"* ]]
do
  let "i+=1"
  if [ $i -gt 30 ]
  then
    echo "Load balancer backend-health error : too many tries"
    exit 1
  fi
  sleep 10
  OUTPUT=$(oci lb backend-health get --backend-name $1 --backend-set-name $2 --load-balancer-id $3)
  echo $OUTPUT
done

# undrain backend from backend set
OUTPUT=$(oci lb backend update --backend-name $1 --backend-set-name $2 --backup false --drain false --load-balancer-id $3 --offline false --weight 1 --wait-for-state SUCCEEDED --wait-for-state FAILED)
echo $OUTPUT
if [[ $OUTPUT == *"FAILED"* ]] ; then
  exit 1
else
  echo "load balancer undrained backend: $1"
fi
exit 0