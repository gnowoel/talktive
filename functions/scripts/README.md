# Reset Trusted User Status Script

This directory contains scripts and documentation for resetting the status of trusted users who have been unfairly restricted due to malicious reports.

## Overview

The `resetTrustedUserStatus` Cloud Function resets the `reportCount` and `revivedAt` fields to `0` for users with good reputation scores (> 0.60). This helps restore functionality for trustworthy users who were deliberately targeted by false reports.

## How It Works

1. **Reputation Calculation**: Uses the new follower-based reputation system where reputation = `followerCount / (followerCount + followeeCount)`
2. **Threshold**: Only resets users with reputation scores above 0.60 (fair level)
3. **Batch Processing**: Processes users in configurable batches to avoid database overload
4. **Safety Features**: Includes dry-run mode and detailed logging

## Setup

### 1. Environment Variables

Set the `ADMIN_TOKEN` environment variable in your Cloud Functions configuration:

```bash
# For Firebase CLI deployment
firebase functions:config:set admin.token="your-secure-admin-token-here"

# For Google Cloud Console
# Go to Cloud Functions > Your Function > Configuration > Environment variables
# Add: ADMIN_TOKEN = your-secure-admin-token-here
```

### 2. Deploy the Function

Make sure the function is included in your `index.ts` and deploy:

```bash
cd functions
npm run deploy
# or
firebase deploy --only functions:resetTrustedUserStatus
```

### 3. Configure the Script

Edit `reset-trusted-users.sh` and update these values:

```bash
# Update these lines in the script:
FUNCTION_URL="https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/resetTrustedUserStatus"
ADMIN_TOKEN="your-secure-admin-token-here"
```

## Usage

### Command Line Options

```bash
./reset-trusted-users.sh [OPTIONS]

Options:
  -d, --dry-run           Perform a dry run (default: true)
  -e, --execute           Execute actual reset (not dry run)
  -b, --batch-size SIZE   Batch size for processing (default: 100)
  -h, --help              Show help message
```

### Examples

```bash
# Dry run to see what would be reset (safe to run)
./reset-trusted-users.sh

# Dry run with smaller batch size
./reset-trusted-users.sh --dry-run --batch-size 50

# Execute actual reset (WARNING: This modifies data!)
./reset-trusted-users.sh --execute

# Execute with custom batch size
./reset-trusted-users.sh --execute --batch-size 200
```

### Using curl directly

```bash
# Dry run
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{"batchSize": 100, "dryRun": "true"}' \
  https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/resetTrustedUserStatus

# Actual execution
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{"batchSize": 100, "dryRun": "false"}' \
  https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/resetTrustedUserStatus
```

## Request Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `batchSize` | integer | 100 | Number of users to process in each batch |
| `dryRun` | boolean/string | false | If true, simulates the operation without making changes |
| `authToken` | string | - | Admin authentication token (can be in body or Authorization header) |

## Response Format

```json
{
  "success": true,
  "message": "Successfully processed 1000 users, reset 250 trusted users with good reputation (score > 0.6)",
  "processedCount": 1000,
  "resetCount": 250,
  "dryRun": false,
  "sampleResetUsers": [
    {
      "userId": "user123",
      "reputationLevel": "good",
      "reputationScore": 0.857
    }
  ],
  "totalResetUsers": 250,
  "reputationThreshold": 0.6,
  "errorCount": 0
}
```

## Reputation Thresholds

The function uses these reputation levels:

| Level | Score Range | Action |
|-------|-------------|---------|
| Excellent | ≥ 0.90 | ✅ Reset |
| Good | ≥ 0.80 | ✅ Reset |
| Fair | ≥ 0.60 | ✅ Reset |
| Poor | ≥ 0.40 | ❌ No reset |
| Very Poor | < 0.40 | ❌ No reset |

## Safety Considerations

### Always Start with Dry Run

```bash
# ALWAYS run this first to see what would be affected
./reset-trusted-users.sh --dry-run
```

### Monitor Logs

Check Cloud Function logs during execution:

```bash
# View logs
firebase functions:log --only resetTrustedUserStatus

# Follow logs in real-time
firebase functions:log --only resetTrustedUserStatus --follow
```

### Batch Size Recommendations

- **Small datasets** (< 1,000 users): Use batch size 50-100
- **Medium datasets** (1,000-10,000 users): Use batch size 100-200
- **Large datasets** (> 10,000 users): Use batch size 200-500

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check that `ADMIN_TOKEN` is set correctly in Cloud Functions environment
   - Verify the token matches in your script

2. **405 Method Not Allowed**
   - Make sure you're using POST requests
   - Check the function URL is correct

3. **Timeout Errors**
   - Reduce batch size
   - The function has a default timeout; consider increasing it for large datasets

4. **Memory Issues**
   - Reduce batch size
   - Consider increasing Cloud Function memory allocation

### Monitoring Progress

The function logs progress every 500 processed users:

```
Progress: 1500/5000 users processed, 375 users reset
Completed batch 15/50 (375 users reset so far)
```

### Rollback

If you need to rollback changes, you would need to:

1. Have a backup of the original `reportCount` and `revivedAt` values
2. Create a separate function to restore those values

**Important**: Always keep database backups before running this function!

## Security Notes

- The `ADMIN_TOKEN` should be a strong, unique secret
- Only authorized administrators should have access to this token
- Consider rotating the token periodically
- Monitor Cloud Function invocation logs for unauthorized access attempts

## Performance

- Processing ~1,000 users takes approximately 30-60 seconds
- Database read operations are optimized by fetching all users at once
- Batch writes prevent overwhelming the Realtime Database
- Function memory usage scales with batch size

## Support

If you encounter issues:

1. Check Cloud Function logs for detailed error messages
2. Verify your configuration matches the setup requirements
3. Test with a dry run first
4. Use smaller batch sizes if experiencing timeouts
