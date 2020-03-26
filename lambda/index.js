const AWS = require('aws-sdk');
const apiVersion = "2016-11-15";
const dryRun = false

const tagsToFilter = tags =>
    Object.keys(tags).map(tag => ({
        Name: `tag:${tag}`,
        Values: tags[tag]
    }))

exports.handler = async(event, context) => {
    if (!event.regions || event.regions.length === 0) {
        console.log("No regions specified.");
        context.fail(event);
        return;
    }
    if (!event.max_age_minutes) {
        console.log("No max_age_minutes specified.");
        context.fail(event);
        return;
    }
    if (!event.tags) {
        console.log("No tags specified.");
        context.fail(event);
        return;
    }
    const { max_age_minutes, regions, tags } = event
    const max_age_ms = max_age_minutes * 60 * 1000
    const threshold_epoch = Date.now() - max_age_ms
    const tagFilters = tagsToFilter(tags)
    console.log("TAGS", tagFilters)
    const params = {
        Filters: [
            ...tagFilters,
            { Name: 'instance-state-name', Values: ['pending', 'running', 'shutting-down', 'stopping', 'stopped'] }
        ]
    };
    const allTerminatedIds = (await Promise.all(regions.map(async region => {
        const ec2 = new AWS.EC2({ region, apiVersion });
        const response = await ec2.describeInstances(params).promise();
        const instanceIds = response.Reservations
            .map(r => r.Instances)
            .flat()
            .filter(i => i.LaunchTime < threshold_epoch)
            .map(i => i.InstanceId)
        console.log(`${region}: Found ${instanceIds.length} instances to terminate`)
        if (instanceIds.length > 0) {
            try {
                await ec2.terminateInstances({ DryRun: dryRun, InstanceIds: instanceIds }).promise();
                console.log(`${region}: terminated`, instanceIds)
                return instanceIds
            }
            catch (e) {
                console.error(e)
            }
        }
        return []
    }))).flat()
    console.log("allTerminatedIds", allTerminatedIds)
    return `terminated ${allTerminatedIds.length} instances`
};

