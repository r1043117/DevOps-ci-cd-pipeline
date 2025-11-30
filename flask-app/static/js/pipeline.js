// Pipeline Status Updater
// Fetches Jenkins pipeline status and updates the visual

function updatePipelineStatus() {
    fetch('/api/pipeline')
        .then(response => response.json())
        .then(data => {
            // Update build number
            const buildNum = document.getElementById('build-number');
            if (data.build_number) {
                buildNum.textContent = `Build #${data.build_number}`;
            } else {
                buildNum.textContent = 'Build: --';
            }

            // Update overall status badge
            const statusBadge = document.getElementById('build-status');
            statusBadge.className = 'status-badge';

            if (data.error) {
                statusBadge.textContent = 'Unavailable';
                statusBadge.classList.add('unknown');
            } else {
                const status = data.result || 'UNKNOWN';
                statusBadge.textContent = status;

                if (status === 'SUCCESS') {
                    statusBadge.classList.add('success');
                } else if (status === 'FAILED' || status === 'FAILURE') {
                    statusBadge.classList.add('failed');
                } else if (status === 'IN_PROGRESS') {
                    statusBadge.classList.add('running');
                } else {
                    statusBadge.classList.add('unknown');
                }
            }

            // Update stages
            if (data.stages && data.stages.length > 0) {
                data.stages.forEach(stage => {
                    const stageEl = document.querySelector(`[data-stage="${stage.name}"]`);
                    if (stageEl) {
                        stageEl.className = 'stage';
                        const status = stage.status;

                        if (status === 'SUCCESS') {
                            stageEl.classList.add('success');
                        } else if (status === 'FAILED' || status === 'FAILURE') {
                            stageEl.classList.add('failed');
                        } else if (status === 'IN_PROGRESS') {
                            stageEl.classList.add('running');
                        } else {
                            stageEl.classList.add('pending');
                        }

                        // Clear the icon text (CSS ::before handles it)
                        const icon = stageEl.querySelector('.stage-icon');
                        if (icon) icon.textContent = '';
                    }
                });
            }

            // Update duration
            const durationEl = document.getElementById('pipeline-duration');
            if (data.duration) {
                const mins = Math.floor(data.duration / 60);
                const secs = data.duration % 60;
                durationEl.textContent = `Duration: ${mins}m ${secs}s`;
            } else {
                durationEl.textContent = '';
            }
        })
        .catch(error => {
            console.error('Error fetching pipeline status:', error);
            const statusBadge = document.getElementById('build-status');
            statusBadge.textContent = 'Error';
            statusBadge.className = 'status-badge unknown';
        });
}

// Initial load
updatePipelineStatus();

// Refresh every 10 seconds
setInterval(updatePipelineStatus, 10000);
