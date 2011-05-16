<?php defined('BASEPATH') OR exit('No direct script access allowed');
/**
 * Pages controller
 *
 * @author 		Phil Sturgeon - PyroCMS Dev Team
 * @modified	Yorick Peterse
 * @package 	PyroCMS
 * @subpackage 	Pages module
 * @category	Modules
 */
class Admin extends Admin_Controller {

	/**
	 * Array containing the validation rules
	 * @access private
	 * @var array
	 */
	private $validation_rules = array(
			array(
				'field' => 'title',
				'label'	=> 'lang:pages.title_label',
				'rules'	=> 'trim|required|max_length[250]'
			),
			array(
				'field' => 'slug',
				'label'	=> 'lang:pages.slug_label',
				'rules'	=> 'trim|required|alpha_dot_dash|max_length[250]'
			),
			array(
				'field' => 'body',
				'label'	=> 'lang:pages.body_label',
				'rules' => 'trim|required'
			),
			array(
				'field' => 'layout_id',
				'label'	=> 'lang:pages.layout_id_label',
				'rules'	=> 'trim|numeric|required'
			),
			array(
				'field'	=> 'css',
				'label'	=> 'lang:pages.css_label',
				'rules'	=> 'trim'
			),
			array(
				'field'	=> 'js',
				'label'	=> 'lang:pages.js_label',
				'rules'	=> 'trim'
			),
			array(
				'field' => 'meta_title',
				'label' => 'lang:pages.meta_title_label',
				'rules' => 'trim|max_length[250]'
			),
			array(
				'field'	=> 'meta_keywords',
				'label' => 'lang:pages.meta_keywords_label',
				'rules' => 'trim|max_length[250]'
			),
			array(
				'field'	=> 'meta_description',
				'label'	=> 'lang:pages.meta_description_label',
				'rules'	=> 'trim'
			),
			array(
				'field' => 'restricted_to[]',
				'label'	=> 'lang:pages.access_label',
				'rules'	=> 'trim|numeric'
			),
			array(
				'field' => 'rss_enabled',
				'label'	=> 'lang:pages.rss_enabled_label',
				'rules'	=> 'trim|numeric'
			),
			array(
				'field' => 'comments_enabled',
				'label'	=> 'lang:pages.comments_enabled_label',
				'rules'	=> 'trim|numeric'
			),
			array(
				'field' => 'is_home',
				'label'	=> 'lang:pages.is_home_label',
				'rules'	=> 'trim|numeric'
			),
			array(
				'field'	=> 'status',
				'label'	=> 'lang:pages.status_label',
				'rules'	=> 'trim|alpha|required'
			),
			array(
				'field' => 'navigation_group_id',
				'label' => 'lang:pages.navigation_label',
				'rules' => 'numeric'
			)
		);

	/**
	 * The ID of the page, used for the validation callback
	 * @access private
	 * @var int
	 */
	private $page_id;

	/**
	 * Constructor method
	 * @access public
	 * @return void
	 */
	public function __construct()
	{
		// Call the parent's constructor
		parent::Admin_Controller();

		// Load the required classes
		$this->load->library('form_validation');

		// Versioning
		$this->load->library('versioning');
		$this->versioning->set_table('pages');

		$this->load->model('pages_m');
		$this->load->model('page_layouts_m');
		$this->load->model('navigation/navigation_m');
		$this->lang->load('pages');

		$this->template->set_partial('shortcuts', 'admin/partials/shortcuts');

		$this->form_validation->set_rules($this->validation_rules);
	}


	/**
	 * Index methods, lists all pages
	 * @access public
	 * @return void
	 */
	public function index()
	{
		// Get the page tree		
		$this->data->pages = $this->pages_m->get_page_tree();
		$this->data->controller =& $this;

		$this->template
			->title($this->module_details['name'])
			->append_metadata( js('jquery/jquery.ui.nestedSortable.js') )
			->append_metadata( js('jquery/jquery.cookie.js') )
			->append_metadata( js('index.js', 'pages') )
			->append_metadata( css('index.css', 'pages') )
			->build('admin/index', $this->data);
	}
	
	/**
	 * Order the pages and record their children
	 * 
	 * @access public
	 * @return string json message
	 */
	public function order()
	{
		$order = $this->input->post('order');

		if (is_array($order))
		{
			//reset all parent > child relations
			$this->pages_m->update_all(array('parent_id' => 0));
			
			foreach ($order as $i => $page)
			{
				//set the order of the root pages
				$this->pages_m->update_by('id', str_replace('page_', '', $page['id']), array('order' => $i));
				
				//iterate through children and set their order and parent
				$this->pages_m->_set_children($page);
			}
			
			// rebuild page URIs
			$this->pages_m->update_lookup($this->input->post('root_pages'));
			
			$this->pyrocache->delete_all('navigation_m');
			$this->pyrocache->delete_all('pages_m');
				
			echo 'Success';
		}
		else
		{
			echo 'Fail';
		}
	}

	/**
	 * Get the details of a page using Ajax
	 * @access public
	 * @param int $page_id The ID of the page
	 * @return void
	 */
	public function ajax_page_details($page_id)
	{
		$page = $this->pages_m->get($page_id);

		$this->load->view('admin/ajax/page_details', array('page' => $page));
	}

	/**
	 * Show a page preview
	 * @access public
	 * @param int $id The ID of the page
	 * @return void
	 */
	public function preview($id = 0)
	{
		$data->page  = $this->pages_m->get($id);

		$this->template->set_layout('modal', 'admin');
		$this->template->build('admin/preview', $data);
	}

	/**
	 * Create a new page
	 * @access public
	 * @param int $parent_id The ID of the parent page
	 * @return void
	 */
	public function create($parent_id = 0)
	{
		// Validate the page
		if ($this->form_validation->run())
	    {
			$input = $this->input->post();

			if ($input['status'] == 'live')
			{
				role_or_die('pages', 'put_live');
			}

			// First create the page
			$page_body		= $input['body'];
			$nav_group_id	= $input['navigation_group_id'];

			unset($input['body'], $input['navigation_group_id']);
			
			if ($id = $this->pages_m->create($input))
			{
				// Create the revision
				$revision_id = $this->versioning->create_revision(array('author_id' => $this->user->id, 'owner_id' => $id, 'body' => $page_body));

				// Update the page row
				$input['revision_id'] = $revision_id;

				$input['restricted_to'] = isset($input['restricted_to']) ? implode(',', $input['restricted_to']) : '';

				// Add a Navigation Link
				if ($nav_group_id)
				{
					$this->load->model('navigation/navigation_m');
					$this->navigation_m->insert_link(array(
						'title'					=> $input['title'],
						'link_type'				=> 'page',
						'page_id'				=> $id,
						'navigation_group_id'	=> (int) $nav_group_id
					));
				}

				if ($this->pages_m->update($id, $input))
				{
					$this->session->set_flashdata('success', lang('pages_create_success'));

					// Redirect back to the form or main page
					$this->input->post('btnAction') == 'save_exit'
						? redirect('admin/pages')
						: redirect('admin/pages/edit/'.$id);
				}
			}

			// Fail
			else
			{
				$this->session->set_flashdata('notice', lang('pages_create_error'));
			}
	    }

		// Loop through each rule
		foreach ($this->validation_rules as $rule)
		{
			$page->{$rule['field']} = $this->input->post($rule['field']);
		}

		$page->restricted_to = $this->input->post('restricted_to');

	    // If a parent id was passed, fetch the parent details
	    if ($parent_id > 0)
	    {
			$page->parent_id 	= $parent_id;
			$parent_page 		= $this->pages_m->get($parent_id);
	    }

	    // Assign data for display
		$data['page'] = & $page;
		$data['parent_page'] = & $parent_page;

		// Set some data that both create and edit forms will need
		self::_form_data();

	    // Load WYSIWYG editor
		$this->template
			->title($this->module_details['name'], lang('pages.create_title'))
			->append_metadata( $this->load->view('fragments/wysiwyg', $this->data, TRUE) )
			->append_metadata( js('codemirror/codemirror.js') )
			->append_metadata( js('form.js', 'pages') )
			->build('admin/form', $data);
	}

	/**
	 * Edit an existing page
	 * @access public
	 * @param int $id The ID of the page to edit
	 * @return void
	 */
	public function edit($id = 0)
	{
		$id OR redirect('admin/pages');

		role_or_die('pages', 'edit_live');

	    // Set the page ID and get the current page
	    $this->page_id 	= $id;
	    $page 			= $this->versioning->get($id);
		$revisions		= $this->versioning->get_revisions($id);

	    // Got page?
	    if ( ! $page)
	    {
			$this->session->set_flashdata('error', lang('pages_page_not_found_error'));
			redirect('admin/pages/create');
	    }

		// It's stored as a CSV list
		$page->restricted_to = explode(',', $page->restricted_to);

		if ($this->form_validation->run())
	    {
			$input = $this->input->post();
			
			if ($page->status != 'live' and $input['status'] == 'live')
			{
				role_or_die('pages', 'put_live');
			}
			
			// Set the data for the revision
			$revision_data = array('author_id' => $this->user->id, 'owner_id' => $id, 'body' => $input['body']);

			// Did the user wanted to restore a specific revision?
			if ($input['use_revision_id'] == $page->revision_id )
			{
				$input['revision_id'] 	= $this->versioning->create_revision($revision_data);
			}
			// Manually restore a revision
			else
			{
				$input['revision_id'] = $input['use_revision_id'];
			}

			$input['restricted_to'] = isset($input['restricted_to']) ? implode(',', $input['restricted_to']) : '';

			// Run the update code with the POST data
			$this->pages_m->update($id, $input);

			// The slug has changed
			if ($this->input->post('slug') != $this->input->post('old_slug'))
			{
				$this->pages_m->reindex_descendants($id);
			}

			// Set the flashdata message and redirect the user
			$link = anchor('admin/pages/preview/'.$id, $this->input->post('title'), 'class="modal-large"');
			$this->session->set_flashdata('success', sprintf(lang('pages_edit_success'), $link));

			// Redirect back to the form or main page
			$this->input->post('btnAction') == 'save_exit'
				? redirect('admin/pages')
				: redirect('admin/pages/edit/'.$id);
	    }

		// Loop through each validation rule
		foreach ($this->validation_rules as $rule)
		{
			if ($this->input->post($rule['field']) !== FALSE)
			{
				$page->{$rule['field']} = set_value($rule['field']);
			}
		}

	    // If a parent id was passed, fetch the parent details
	    if ($page->parent_id > 0)
	    {
			$parent_page = $this->pages_m->get($page->parent_id);
	    }

	    // Assign data for display
	    $this->data->page 			=& $page;
		$this->data->revisions		=& $revisions;
	    $this->data->parent_page 	=& $parent_page;

		self::_form_data();

		$this->template
			->title($this->module_details['name'], sprintf(lang('pages.edit_title'), $page->title))

			// Load WYSIWYG Editor
			->append_metadata( $this->load->view('fragments/wysiwyg', $this->data, TRUE) )

			// Load form specific JavaScript
			->append_metadata( js('codemirror/codemirror.js') )
			->append_metadata( js('form.js', 'pages') )
			->build('admin/form', $this->data);
	}


	private function _form_data()
	{
		$page_layouts = $this->page_layouts_m->get_all();
		$this->template->page_layouts = array_for_select($page_layouts, 'id', 'title');

		// Load navigation list
		$this->load->model('navigation/navigation_m');
		$navigation_groups = $this->navigation_m->get_groups();
		$this->template->navigation_groups = array_for_select($navigation_groups, 'id', 'title');

		$this->load->model('groups/group_m');
		$groups = $this->group_m->get_all();
		foreach($groups as $group)
		{
			$group->name !== 'admin' && $group_options[$group->id] = $group->name;
		}
		$this->template->group_options = $group_options;
	}

	/**
	 * Delete an existing page
	 * @access public
	 * @param int $id The ID of the page to delete
	 * @return void
	 */
	public function delete($id = 0)
	{
		role_or_die('pages', 'delete_live');

		// Attention! Error of no selection not handeled yet.
		$ids = ($id) ? array($id) : $this->input->post('action_to');

		// Go through the array of slugs to delete
		foreach ($ids as $id)
		{
			if ($id !== 1)
			{
				$deleted_ids = $this->pages_m->delete($id);

				// Wipe cache for this model, the content has changd
				$this->pyrocache->delete_all('pages_m');
				$this->pyrocache->delete_all('navigation_m');
			}

			else
			{
				$this->session->set_flashdata('error', lang('pages_delete_home_error'));
			}
		}

		// Some pages have been deleted
		if ( ! empty($deleted_ids))
		{
			// Only deleting one page
			if ( count($deleted_ids) == 1 )
			{
				$this->session->set_flashdata('success', sprintf(lang('pages_delete_success'), $deleted_ids[0]));
			}
			else // Deleting multiple pages
			{
				$this->session->set_flashdata('success', sprintf(lang('pages_mass_delete_success'), count($deleted_ids)));
			}
		}

		else // For some reason, none of them were deleted
		{
			$this->session->set_flashdata('notice', lang('pages_delete_none_notice'));
		}

		redirect('admin/pages');
	}

	/**
	 * Show a diff between two revisions
	 *
	 * @author Yorick Peterse - PyroCMS Dev Team
	 * @access public
	 * @param int $id_1 The ID of the first revision to compare
	 * @param int $id_2 The ID of the second revision to compare
	 * @return void
	 */
	public function compare($id_1, $id_2)
	{
		// Create the diff using mixed mode
		$rev_1 = $this->versioning->get_by_revision($id_1);
		$rev_2 = $this->versioning->get_by_revision($id_2);
		$diff  = $this->versioning->compare_revisions($rev_1->body, $rev_2->body, 'mixed');

		// Output the results
		$data['difference'] = $diff;
		$this->template->set_layout('modal', 'admin')
				->build('admin/revisions/compare', $data);
	}

	/**
	 * Show a preview of a revision
	 *
	 * @author Yorick Peterse - PyroCMS Dev Team
	 * @access public
	 * @param int $id The ID of the revision to preview
	 * @return void
	 */
	public function preview_revision($id)
	{
		// Easy isn't it?
		$data['revision'] = $this->versioning->get_by_revision($id);
		$this->template->set_layout('modal', 'admin')
				->build('admin/revisions/preview', $data);
	}
	
	/**
	 * Build the html for the admin page tree view
	 *
	 * @author Jerel Unruh - PyroCMS Dev Team
	 * @access public
	 * @param array $page Current page
	 */
	
	public function tree_builder($page)
	{
		if(isset($page['children'])):
		
				foreach($page['children'] as $page): ?>
			
					<li id="page_<?php echo $page['id']; ?>">
						<div>
							<a href="#" rel="<?php echo $page['id'] . '">' . $page['title']; ?></a>
						</div>
					
				<?php if(isset($page['children'])): ?>
						<ol>
								<?php $this->tree_builder($page); ?>
						</ol>
					</li>
				<?php else: ?>
					</li>
				<?php endif; ?>
				
			<?php endforeach; ?>
			
		<?php endif;
	}
}
