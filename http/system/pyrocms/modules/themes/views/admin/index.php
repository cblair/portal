<?php if ($themes): ?>

	<?php echo form_open('admin/themes/set_default'); ?>
	<table>
		<thead>
			<tr>
				<th width="150" class="align-center"><?php echo lang('themes.default_theme_label'); ?></th>
				<th width="15%"><?php echo lang('themes.theme_label'); ?></th>
				<th><?php echo lang('themes.description_label'); ?></th>
				<th width="15%"><?php echo lang('themes.author_label'); ?></th>
				<th width="100" class="align-center"><?php echo lang('themes.version_label'); ?></th>
				<th width="220" class="align-center"><?php echo lang('themes.actions_label'); ?></th>
			</tr>
		</thead>
		<tfoot>
			<tr>
				<td colspan="6">
					<div class="inner"><?php $this->load->view('admin/partials/pagination'); ?></div>
				</td>
			</tr>
		</tfoot>
		<tbody>
			<?php foreach($themes as $theme): ?>
			<tr>
				<td class="align-center"><input type="radio" name="theme" value="<?php echo $theme->slug; ?>" <?php echo $this->settings->default_theme == $theme->slug ? 'checked="checked" ' : ''; ?>/></td>
				<td><?php if (!empty($theme->website)): ?>
								<?php echo anchor($theme->website, $theme->name, array('target'=>'_blank')); ?>
							<?php else: ?>
								<?php echo $theme->name; ?>
							<?php endif; ?></td>
				<td><?php echo $theme->description; ?></td>
				<td><?php if ($theme->author_website): ?>
								<?php echo anchor($theme->author_website, $theme->author, array('target'=>'_blank')); ?>
							<?php else: ?>
								<?php echo $theme->author; ?>
							<?php endif; ?></td>

				<td class="align-center"><?php echo $theme->version; ?></td>
				<td class="align-center buttons buttons-small">
					<a href="<?php echo $theme->screenshot; ?>" rel="screenshots" title="<?php echo $theme->name; ?>" class="button"><?php echo lang('buttons.preview'); ?></a>
					<?php echo anchor('admin/themes/delete/' . $theme->slug, lang('buttons.delete'), 'class="confirm button delete"'); ?>
				</td>
			</tr>
			<?php endforeach; ?>
		</tbody>
	</table>
	
	<div class="buttons align-right padding-top">
		<?php $this->load->view('admin/partials/buttons', array('buttons' => array('save') )); ?>
	</div>
	
	<?php echo form_close(); ?>

	<script type="text/javascript">
		jQuery(function($) {
			$("a[rel='screenshots']").colorbox({width: "40%", height: "50%"});
		});
	</script>

<?php else: ?>
	<div class="blank-slate">
		<h2><?php echo lang('themes.no_themes_installed'); ?></h2>
	</div>
<?php endif; ?>